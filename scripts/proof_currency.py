#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""proof_currency.py —— 覆盖率台账的 proven 只认「当前有效」的证明（ledger-cv lane）。

## 为什么

oldcert-triage lane 实测：rewrite_coverage.py / coverage_three_axis.py 都不读证书，
只读 round 台账与已跟踪 receipt，receipt 收录只查 impl 字节、不查脚本闭包。于是证书
validate 判非 current-valid（主要是 green_child_script_closure_changed:scripts/fm_eq.tcl）
的目标仍记 PROVEN_DIRECT。用户批准的口径：

  1. PROVEN_DIRECT 只给证明（证书或 receipt）对当前 HEAD current-valid 的目标；
  2. 不 current-valid、但被一个 current-valid 父证明白盒覆盖（WB1–WB6）的，记
     PROVEN_IN_CONE(superseded_by=<父>)；
  3. 都不满足的不记 proven。

## 判据（★不另写一份★）

* 证书：`fm_verdict._child_cert_current`（= `proof_certificate.validate_certificate_current`），
  与 batch_reproof validate / green_child 同一个函数。
* 只有 receipt 的根（NewCSR / CSR / ExeUnit_7 这类）：用 `make_proof_certificate.build_certificate`
  从**已跟踪**的 evidence 目录在内存里派生证书文档（生成器自己的全部拒收条件照样生效：
  dirty/provisional/非合格 verdict/老格式闭包/缺 RUN_CONTEXT/缺 sidecar/工具版本解析不到……），
  再交给**同一个** `validate_certificate_current` 在 HEAD 上判。派生失败 = 不 current-valid。
  只做一件性能上的事：先用同一个 `recompute_closure_at` 在 HEAD 上验 receipt 的 impl 闭包，
  对不上的不再派生（这一条本来就是 validate 的必要条件，不放宽任何东西）。
* WB1–WB6：从 oldcert_triage.py 抽出来的同一份代码（本模块 `WhiteBox`），oldcert_triage 改为 import。
  父集合 = 全部 current-valid 证明（证书或 receipt 派生的文档）。

## 产物

`evaluate()` → `Currency`：
  cv[t]          = 当前有效的证明文档（cert-shaped dict）
  via[t]         = 'certificate' | 'receipt:<evidence/.../receipt.json>'
  why[t]         = 非 current-valid 根的原因串（证书原因优先，其次最新一份 receipt 的原因）
  superseded[t]  = WB1–WB6 成立的最近 current-valid 父
`tier(name)` → ('PROVEN_DIRECT', None) | ('PROVEN_IN_CONE', parent) | ('NOT_CURRENT', why) | ('NO_PROOF', None)

★PROVEN_IN_CONE(superseded_by) 不是逐条核验行★：WB2 只证明 T 在父证明里被白盒展开，不证明 T 的
每个输出都是父的 compare point（oldcert-triage §6/§7）。rewrite_coverage 不把它并入 proven，
也不并入 incl_cone（那一行只认 verif/proven_in_cone_verified.tsv 的 R1–R10 核验行），只单列。
"""
import collections
import contextlib
import io
import json
import os
import pathlib
import re
import subprocess
import sys

_HERE = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(os.environ.get('XSSV_HOME') or _HERE.parent)
G1 = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical'))
CERT_DIR_REL = 'verif/proof_certificates'
NON_CERT = ('POLICY', 'schema-v1')
PASS = ('SUCCEEDED', 'PASS_DEAD_REF')

# ----------------------------------------------------------------------------
# WB1–WB6（自 oldcert_triage.py 原样抽出；判据说明见 oldcert_triage.py docstring）
# ----------------------------------------------------------------------------
_INST = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+(?:#\s*\(|[A-Za-z_\\][A-Za-z0-9_$]*\s*\()')
_MOD = re.compile(r'^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)')
_IMOD = re.compile(r'^\s*module\s+(?:automatic\s+|static\s+)?([A-Za-z_][A-Za-z0-9_$]*)')
_IINST = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+(?:#|[A-Za-z_][A-Za-z0-9_$]*\s*(?:\[[^\]]*\]\s*)?(?:\(|$))')
_PKG = re.compile(r'^\s*package\s+([A-Za-z_][A-Za-z0-9_$]*)')


def golden_graph(g1=None):
    """G1 golden：module -> 定义文件；module -> 例化的 module 集合。"""
    g1 = pathlib.Path(g1 or G1)
    defs, raw = {}, {}
    for f in sorted((g1 / 'golden-rtl').glob('*.sv')):
        cur = None
        for ln in f.read_text(errors='replace').splitlines():
            m = _MOD.match(ln)
            if m:
                cur = m.group(1)
                defs[cur] = f.name
                raw[cur] = set()
                continue
            if cur is None:
                continue
            if ln.strip().startswith('endmodule'):
                cur = None
                continue
            m = _INST.match(ln)
            if m:
                raw[cur].add(m.group(1))
    known = set(defs)
    return defs, {k: v & known for k, v in raw.items()}


def reach(top, inst, allowed_files, defs, cut):
    seen, st = set(), [top]
    while st:
        m = st.pop()
        if m in seen:
            continue
        seen.add(m)
        if m in cut and m != top:
            continue
        if defs.get(m) not in allowed_files:
            continue
        st.extend(inst.get(m, ()))
    return seen


def needed_impl(doc, repo=None, _cache={}):
    """WB4 用：T 证明 impl 闭包里 rtl/ 下、**T 自己真正用到**的文件 {(path, sha256)}。
    从 module T 出发，在该闭包 rtl/ 文件定义的模块里按例化可达；再加被可达文件 import/`::` 引用的
    package 文件、被 `include 的文件。同一 UT 的兄弟变体文件不算 T 的依赖。"""
    repo = pathlib.Path(repo or REPO)
    ents = [(e['path'], e['sha256']) for e in doc['input_closure']['impl']
            if e.get('kind') == 'repo' and e['path'].startswith('rtl/')]
    mdef, minst, pkgs, text = {}, {}, {}, {}
    for path, _sha in ents:
        key = (str(repo), path)
        if key not in _cache:
            try:
                _cache[key] = (repo / path).read_text(errors='replace')
            except OSError:
                _cache[key] = ''
        txt = _cache[key]
        text[path] = txt
        cur = None
        for ln in txt.splitlines():
            m = _IMOD.match(ln)
            if m:
                cur = m.group(1)
                mdef[cur] = path
                minst.setdefault(cur, set())
                continue
            m = _PKG.match(ln)
            if m:
                pkgs[m.group(1)] = path
            if cur:
                m = _IINST.match(ln)
                if m:
                    minst[cur].add(m.group(1))
    top = doc['variant']
    if top not in mdef:
        return set(ents)                     # 找不到定义就退回全集（更严）
    seen, st = set(), [top]
    while st:
        m = st.pop()
        if m in seen or m not in mdef:
            continue
        seen.add(m)
        st.extend(minst.get(m, ()))
    files = {mdef[m] for m in seen}
    grow = True
    while grow:
        grow = False
        for pk, pf in pkgs.items():
            if pf in files:
                continue
            if any(re.search(r'\b%s\s*::' % re.escape(pk), text[f]) or
                   re.search(r'\bimport\s+%s\b' % re.escape(pk), text[f]) for f in files):
                files.add(pf)
                grow = True
        for path, _sha in ents:
            if path not in files and any(('`include \"%s\"' % os.path.basename(path)) in text[f] for f in files):
                files.add(path)
                grow = True
    return {(p, s) for p, s in ents if p in files}


def allow_of(doc, repo=None):
    repo = pathlib.Path(repo or REPO)
    rec = (doc.get('proof_config', {}).get('declarations') or {}).get('allow')
    if not rec:
        return None
    p = repo / rec['path']
    return json.loads(p.read_text()) if p.exists() else None


class WhiteBox(object):
    """WB1–WB6。parents = {name: current-valid 证明文档}（WB1 由调用方保证：只传 current-valid 的）。"""

    def __init__(self, parents, defs, inst, repo=None, allows=None):
        self.repo = pathlib.Path(repo or REPO)
        self.defs, self.inst = defs, inst
        self.parents = dict(parents)
        self.allows = dict(allows or {})
        self.pinfo = {}
        for p, d in self.parents.items():
            if p not in self.allows:
                self.allows[p] = allow_of(d, self.repo)
            gfiles = {os.path.basename(e['path']): e['sha256'] for e in d['input_closure']['golden']}
            impl = {(e['path'], e['sha256']) for e in d['input_closure']['impl'] if e.get('kind') == 'repo'}
            implg = {os.path.basename(e['path']) for e in d['input_closure']['impl'] if e.get('kind') == 'golden'}
            cut = {o.get('design') for o in (self.allows.get(p) or {}).get('objects') or []}
            self.pinfo[p] = (gfiles, impl, implg, cut, d.get('proof_mode'), d['variant'])
        self.reach_cache, self.inst_cache = {}, {}

    def order(self, names):
        """最近的父在前：golden 闭包小者优先。"""
        return sorted(names, key=lambda p: (len(self.pinfo[p][0]), p))

    def reach_of(self, p):
        if p not in self.reach_cache:
            gfiles, _i, _g, cut, _m, var = self.pinfo[p]
            self.reach_cache[p] = reach(var, self.inst, set(gfiles), self.defs, cut)
        return self.reach_cache[p]

    def impl_insts(self, p):
        """WB6：父 impl 闭包 rtl/ 文件里被例化的模块名集合。"""
        if p not in self.inst_cache:
            names = set()
            for path, _s in self.pinfo[p][1]:
                if not path.startswith('rtl/'):
                    continue
                for ln in (self.repo / path).read_text(errors='replace').splitlines():
                    m = _IINST.match(ln)
                    if m:
                        names.add(m.group(1))
            self.inst_cache[p] = names
        return self.inst_cache[p]

    def parents_of(self, t, d):
        """满足 WB1–WB6 的父（最近者在前）。d = T 的证明文档（证书，或 receipt 的闭包）。"""
        tg = {os.path.basename(e['path']): e['sha256'] for e in d['input_closure']['golden']}
        tfile = self.defs.get(d['variant'])
        tsha = tg.get(tfile)
        timpl = needed_impl(d, self.repo)
        if not tfile or tsha is None or not timpl:
            return []                                                   # 证据不全 → fail-closed
        out = []
        for p in self.parents:
            if p == t:
                continue
            gfiles, impl, implg, cut, mode, _var = self.pinfo[p]
            if tfile not in gfiles:
                continue
            if gfiles[tfile] != tsha:                                   # WB3
                continue
            if mode == 'signoff-strict':
                pass                                                    # WB5（strict 无黑盒）
            elif mode == 'assembly':
                if d['variant'] in cut:
                    continue                                            # WB5
            else:
                continue
            if tfile in implg or not timpl <= impl:                     # WB4
                continue
            if d['variant'] not in self.reach_of(p):                    # WB2
                continue
            if d['variant'] not in self.impl_insts(p):                  # WB6
                continue
            out.append(p)
        return self.order(out)


# ----------------------------------------------------------------------------
# current-valid
# ----------------------------------------------------------------------------
class BatchRepo(object):
    """proof_certificate.Repo 的**同语义**快读版：show() 走一个常驻 `git cat-file --batch`，
    其余方法原样委托。只换读法不换判据——返回值与 Repo.show 逐字节相同（不存在 → None）。
    起因：实测一份 receipt 的预筛要 ~25 次 git 子进程（0.24 s），2,735 份就是 11 分钟。"""

    def __init__(self, inner):
        self._inner = inner
        self.path = inner.path
        self._cache = {}
        self._p = None
        self._commit = {}

    def __getattr__(self, k):
        return getattr(self._inner, k)

    def _proc(self):
        if self._p is None:
            self._p = subprocess.Popen(['git', 'cat-file', '--batch'], cwd=self.path,
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        return self._p

    def _resolve(self, commit):
        # rev-parse 一次，把 'HEAD' 之类钉成 40-hex（cat-file 对 <rev>:<path> 的解析与 git show 相同）
        if commit not in self._commit:
            self._commit[commit] = self._inner.rev_parse(commit) or commit
        return self._commit[commit]

    def show(self, commit, path):
        key = (commit, path)
        if key in self._cache:
            return self._cache[key]
        if '\n' in path or '\n' in commit:
            out = self._inner.show(commit, path)
        else:
            p = self._proc()
            p.stdin.write(('%s:%s\n' % (self._resolve(commit), path)).encode())
            p.stdin.flush()
            hdr = p.stdout.readline().decode().rstrip('\n').split(' ')
            if len(hdr) == 3 and hdr[1] == 'blob':
                out = p.stdout.read(int(hdr[2]))
                p.stdout.read(1)
            elif len(hdr) == 3:                              # tree 等：git show 会给出非 blob 文本，退回原路
                p.stdout.read(int(hdr[2]))
                p.stdout.read(1)
                out = self._inner.show(commit, path)
            else:                                            # missing / ambiguous
                out = None
        self._cache[key] = out
        return out

    def rev_parse(self, rev):
        if rev not in self._commit:
            self._commit[rev] = self._inner.rev_parse(rev)
        return self._commit[rev]


def _git(repo, *a):
    return subprocess.check_output(['git', '-C', str(repo)] + list(a)).decode()


_RUN_TS = re.compile(r'-(\d{8}T\d{6}Z)-')


def tracked_green_receipts(repo=None):
    """{top: [receipt 相对路径, ...]}（已跟踪、合格 verdict；最新 run 在前）。"""
    repo = pathlib.Path(repo or REPO)
    out = collections.defaultdict(list)
    for rel in _git(repo, 'ls-files', 'evidence/*/receipt.json').split():
        try:
            d = json.loads((repo / rel).read_text())
        except (OSError, ValueError):
            continue
        if d.get('verdict') not in PASS or not d.get('top'):
            continue
        m = _RUN_TS.search(d.get('run_id') or '')
        out[d['top']].append(((m.group(1) if m else ''), rel, d))
    return {t: [(rel, d) for _k, rel, d in sorted(v, key=lambda x: (x[0], x[1]), reverse=True)]
            for t, v in out.items()}


def tracked_certs(repo=None):
    repo = pathlib.Path(repo or REPO)
    return sorted(pathlib.Path(p).stem for p in _git(repo, 'ls-files', CERT_DIR_REL + '/*.json').split()
                  if pathlib.Path(p).stem not in NON_CERT)


def receipt_closure_doc(rec):
    """非 current-valid 的 receipt 根做 WB 判定用的最小文档（只取闭包）；老格式（缺 kind）返回 None。"""
    impl = rec.get('impl_closure') or []
    if not impl or any('kind' not in e for e in impl):
        return None
    gold = [dict(e, kind=e.get('kind', 'golden')) for e in rec.get('golden_closure') or []]
    return {'variant': rec.get('top'), 'input_closure': {'golden': gold, 'impl': impl}}


class Currency(object):
    def __init__(self):
        self.cv, self.via, self.why, self.superseded = {}, {}, {}, {}
        self.roots = set()
        self.head = None

    def to_json(self):
        return {'cv': self.cv, 'via': self.via, 'why': self.why, 'superseded': self.superseded,
                'roots': sorted(self.roots), 'head': self.head}

    @classmethod
    def from_json(cls, j):
        r = cls()
        r.cv, r.via, r.why, r.superseded = j['cv'], j['via'], j['why'], j['superseded']
        r.roots, r.head = set(j['roots']), j['head']
        return r

    def tier(self, name):
        if name in self.cv:
            return 'PROVEN_DIRECT', None
        if name in self.superseded:
            return 'PROVEN_IN_CONE', self.superseded[name]
        if name in self.why:
            return 'NOT_CURRENT', self.why[name]
        return 'NO_PROOF', None


def _result_cache_path(repo, head_commit, g1):
    """整次 evaluate 的结果缓存（性能）：只在**已跟踪文件全干净**时用 —— 此时全部输入 = HEAD 的字节
    （证书 / receipt / evidence / rtl / 判据脚本本身）+ G1（MANIFEST 与 CANONICAL_ID 的 sha 进键）。
    脏树（含 staged）一律不读不写，现算。PROOF_CURRENCY_NO_CACHE=1 强制现算。"""
    import hashlib
    if os.environ.get('PROOF_CURRENCY_NO_CACHE'):
        return None
    st = subprocess.run(['git', '-C', str(repo), 'status', '--porcelain', '--untracked-files=no'],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if st.returncode != 0 or st.stdout.strip():
        return None
    try:
        gk = hashlib.sha256((pathlib.Path(g1) / 'MANIFEST.tsv').read_bytes() +
                            (pathlib.Path(g1) / 'CANONICAL_ID.txt').read_bytes()).hexdigest()[:16]
    except OSError:
        return None
    return _cache_dir('proof_currency_result') / ('%s-%s.json' % (head_commit, gk))


def _derive_from_receipt(repo, evdir, g1):
    """已跟踪 evidence 目录 → 内存里的证书文档（make_proof_certificate 的全部拒收条件生效）。"""
    import make_proof_certificate as MPC
    buf = io.StringIO()
    try:
        with contextlib.redirect_stderr(buf):
            doc = MPC.build_certificate(str(repo), str(evdir), g1_root=str(g1),
                                        now=__import__('datetime').datetime(1970, 1, 1))
        return doc, None
    except SystemExit:
        msg = buf.getvalue().strip().splitlines()
        return None, 'receipt_not_certifiable:%s' % ((msg[-1] if msg else '?')[:160]).replace('\t', ' ')
    except Exception as e:                                  # noqa: BLE001  任何异常 = 派生不出 = 不 current-valid
        return None, 'receipt_not_certifiable:%s:%s' % (type(e).__name__, str(e)[:120].replace('\t', ' '))


def _script_prefilter(pc_repo, head, rec, evdir):
    """脚本闭包的必要条件，按 build_certificate + validate 的**同一组函数、同一顺序**先算一遍：
    script_closure.list 每行经 make_proof_certificate._relativize_script（在 impl_commit 上按内容相对化）
    得到 repo 路径，再用 proof_certificate.recompute_closure_at 在 HEAD 上复算。不过 ⇒ validate 必然
    给 green_child_script_closure_changed/missing，派生前就短路（只省时间，判据不变）。"""
    import make_proof_certificate as MPC
    import proof_certificate as PC
    scl = evdir / 'sidecar' / 'script_closure.list'
    ic = rec.get('impl_commit') or ''
    if not scl.exists() or pc_repo.rev_parse(ic) != ic:
        return None                                         # 交给 build_certificate 给出原因
    ents = []
    for ln in scl.read_text().splitlines():
        c = ln.rstrip('\n').split('\t')
        if len(c) != 3:
            continue
        rel, kind = MPC._relativize_script(pc_repo, ic, c[0], c[2])
        ents.append({'path': rel, 'kind': kind, 'sha256': c[2]})
    _ok, changed, missing = PC.recompute_closure_at(pc_repo, head, ents)
    t = rec.get('top')
    if missing:
        return 'green_child_script_closure_missing_at_parent:%s:%s' % (t, missing[0])
    if changed:
        return 'green_child_script_closure_changed:%s:%s' % (t, changed[0])
    return None


def receipt_prefilter(ctx, rec, evdir):
    """validate 的必要条件提前算（impl 闭包 / 脚本闭包在 HEAD 上复算，同一组函数）→ None | 原因。"""
    import proof_certificate as PC
    t = rec.get('top')
    impl = rec.get('impl_closure') or []
    if not impl or any('kind' not in e for e in impl):
        return 'receipt_old_format_closure'
    _ok, changed, missing = PC.recompute_closure_at(ctx['repo'], ctx['commit'], impl)
    if missing:
        return 'green_child_closure_missing_at_parent:%s:%s' % (t, missing[0])
    if changed:
        return 'green_child_closure_changed:%s:%s' % (t, changed[0])
    return _script_prefilter(ctx['repo'], ctx['commit'], rec, pathlib.Path(evdir))


def validate_receipt(ctx, canon, evdir, rec, g1, repo=None, prefiltered=False):
    """一份 receipt（证据目录 evdir）对 ctx['commit'] 是否 current-valid → (doc, None) | (None, 原因)。
    判据 = make_proof_certificate.build_certificate 的拒收条件 + proof_certificate.validate_certificate_current；
    receipt_prefilter 是 validate 的必要条件提前算，只为不白跑派生。"""
    import proof_certificate as PC
    repo = pathlib.Path(repo or REPO)
    evdir = pathlib.Path(evdir)
    t = rec.get('top')
    if not prefiltered:
        why = receipt_prefilter(ctx, rec, evdir)
        if why:
            return None, why
    doc, derr = _derive_from_receipt(repo, evdir, g1)
    if derr:
        return None, derr
    r = PC.validate_certificate_current(
        ctx['repo'], ctx['commit'], t, doc, expect_canonical=canon, policy=ctx['policy'],
        fm_targets=ctx['targets'], fm_targets_unresolved=ctx['unresolved'], g1_root=str(g1))
    return (doc, None) if r is True else (None, str(r))


def _cache_dir(name):
    import tempfile
    d = pathlib.Path(tempfile.gettempdir()) / name
    d.mkdir(parents=True, exist_ok=True)
    return d


def _ftu_both(args):
    """子进程里算一个 commit 的两个引擎（fm_target_universe 原函数，不改）。"""
    repo, c = args
    import fm_target_universe as FTU
    try:
        rx = FTU.targets_at_regex(repo, c)
    except Exception:                                       # noqa: BLE001  失败不落盘，留给原路径现算报错
        return c, None
    try:
        mk = FTU._targets_at_make_uncached(repo, c, 8)
    except Exception:                                       # noqa: BLE001
        return c, None
    return c, {'regex': [rx[0], rx[1]], 'make': mk}


_RX_MEMO = {}


def install_target_universe_memo(repo, commits, workers=3):
    """性能：fm_target_universe.targets_at(engine='both') 每个 commit 要 git archive 265 MB + 611 个 make
    （~9 s）再加 611 次 git show 的 regex 引擎（~11 s）；build_certificate 每派生一份就按 impl_commit 问一次。
    这里按 commit 预算两个引擎（多进程），放进进程内缓存，并落盘
    $TMPDIR/proof_currency_ftu/<commit>.json 给下一个进程用。
    ★不改判据★：targets_at 本身照旧跑、照旧交叉校验两个引擎（不一致照样 EngineDisagree）；缓存的是两个
    原函数对**不可变 commit 字节**的返回值，键是 40-hex commit；任一引擎失败不落盘，留给原路径现算、现报错。"""
    import concurrent.futures as fut
    import fm_target_universe as FTU
    if not getattr(FTU.targets_at_regex, '_proof_currency_memo', False):
        orig = FTU.targets_at_regex

        def targets_at_regex(r, c):
            k = (str(r), c)
            if k in _RX_MEMO:
                out, unres = _RX_MEMO[k]
                return {t: list(v) for t, v in out.items()}, list(unres)
            return orig(r, c)
        targets_at_regex._proof_currency_memo = True
        FTU.targets_at_regex = targets_at_regex
    d = _cache_dir('proof_currency_ftu')
    todo = []

    rk = str(pathlib.Path(repo).resolve())

    def install(c, v):
        _RX_MEMO[(rk, c)] = (v['regex'][0], v['regex'][1])
        FTU._MAKE_CACHE[(rk, c)] = {t: list(x) for t, x in v['make'].items()}
    for c in sorted(set(commits)):
        if not re.match(r'^[0-9a-f]{40}$', c or ''):
            continue
        if (rk, c) in _RX_MEMO:
            continue
        f = d / (c + '.json')
        if f.exists():
            try:
                install(c, json.loads(f.read_text()))
                continue
            except (OSError, ValueError, KeyError):
                pass
        todo.append(c)
    if not todo:
        return
    with fut.ProcessPoolExecutor(max_workers=workers) as ex:
        for c, v in ex.map(_ftu_both, [(rk, c) for c in todo]):
            if v is None:
                continue
            install(c, v)
            tmp = d / ('.%s.%d.tmp' % (c, os.getpid()))
            tmp.write_text(json.dumps(v, sort_keys=True))
            os.replace(str(tmp), str(d / (c + '.json')))


_MEMO = {}


def evaluate(repo=None, head='HEAD', g1=None, cert_validate=None, receipt_validate=None,
             defs_inst=None):
    """全部证明根的 current-valid 判定 + WB 父。cert_validate / receipt_validate 仅供测试注入。
    同一进程内按 (repo, HEAD commit, G1) 记忆（判据只读 commit 字节与 G1，不读工作树里的证书/receipt
    以外的东西；覆盖率空壳闸一个进程里连跑三次 build()）。"""
    repo = pathlib.Path(repo or REPO)
    g1 = pathlib.Path(g1 or G1)
    memo_key = disk = None
    if cert_validate is None and receipt_validate is None and defs_inst is None:
        memo_key = (str(repo.resolve()), _git(repo, 'rev-parse', head).strip(), str(g1))
        if memo_key in _MEMO:
            return _MEMO[memo_key]
        disk = _result_cache_path(repo, memo_key[1], g1)
        if disk is not None and disk.exists():
            try:
                res = Currency.from_json(json.loads(disk.read_text()))
                _MEMO[memo_key] = res
                return res
            except (OSError, ValueError, KeyError):
                pass
    sys.path.insert(0, str(_HERE))
    import proof_certificate as PC
    res = Currency()
    certs = tracked_certs(repo)
    rcpts = tracked_green_receipts(repo)
    res.roots = set(certs) | set(rcpts)

    if cert_validate is None or receipt_validate is None:
        os.environ.setdefault('XSSV_HOME', str(repo))
        import fm_verdict as fv
        ctx, err = fv._cert_ctx(head)
        if err:
            raise SystemExit('proof_currency: cert ctx 失败（fail-closed）：%s' % err)
        ctx['repo'] = BatchRepo(ctx['repo'])                # 同语义快读（见 BatchRepo）
        canon = (g1 / 'CANONICAL_ID.txt').read_text().strip()
        res.head = ctx['commit']
        if cert_validate is None:
            def cert_validate(t):
                return fv._child_cert_current(ctx, t, canon)

    cert_docs, cert_res = {}, {}
    for t in certs:
        cert_docs[t] = json.loads((repo / CERT_DIR_REL / (t + '.json')).read_text())
        cert_res[t] = cert_validate(t)
        if cert_res[t] is True:
            res.cv[t] = cert_docs[t]
            res.via[t] = 'certificate'
        else:
            res.why[t] = str(cert_res[t])

    advanced = set()
    if receipt_validate is None:
        # 先算全部必要条件（纯函数），再按 impl_commit 并行预取 make 引擎，最后派生 + validate
        pre = {}
        for t in sorted(rcpts):
            if t in res.cv:
                continue
            for rel, rec in rcpts[t]:
                pre[rel] = receipt_prefilter(ctx, rec, (repo / rel).parent)
        install_target_universe_memo(repo, [rec.get('impl_commit') for t in rcpts for rel, rec in rcpts[t]
                                            if rel in pre and pre[rel] is None])

        def receipt_validate(t, rel, rec):
            if pre[rel] is not None:
                return None, pre[rel]
            advanced.add(rel)
            return validate_receipt(ctx, canon, (repo / rel).parent, rec, g1, repo, prefiltered=True)

    for t in sorted(rcpts):
        if t in res.cv:
            continue
        first_why, first_adv = None, False
        for rel, rec in rcpts[t]:
            doc, why = receipt_validate(t, rel, rec)
            if doc is not None:
                res.cv[t] = doc
                res.via[t] = 'receipt:' + rel
                res.why.pop(t, None)
                break
            # 原因取最新一份；但若有一份过了闭包预筛、死在派生 / validate 的后段，报那一份（更接近真因）
            if first_why is None or (rel in advanced and not first_adv):
                first_why, first_adv = why, rel in advanced
        if t not in res.cv and t not in res.why:
            res.why[t] = 'receipt:%s' % first_why

    # ---- WB：非 current-valid 根 → 最近 current-valid 白盒父 ----------------
    defs, inst = defs_inst if defs_inst else golden_graph(g1)
    wb = WhiteBox(res.cv, defs, inst, repo)
    for t in sorted(res.why):
        d = cert_docs.get(t)
        if d is None:
            for _rel, rec in rcpts.get(t, ()):
                d = receipt_closure_doc(rec)
                if d is not None:
                    break
        if d is None:
            continue
        ps = wb.parents_of(t, d)
        if ps:
            res.superseded[t] = ps[0]
    if memo_key:
        _MEMO[memo_key] = res
        if disk is not None:
            tmp = disk.with_name('.%s.%d.tmp' % (disk.name, os.getpid()))
            tmp.write_text(json.dumps(res.to_json(), sort_keys=True))
            os.replace(str(tmp), str(disk))
    return res


def main():
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', help='逐根写 target\\ttier\\tdetail\\tvia')
    a = ap.parse_args()
    res = evaluate()
    c = collections.Counter(res.tier(t)[0] for t in res.roots)
    print('proof_currency @ %s：根 %d；%s' % ((res.head or '?')[:12], len(res.roots), dict(sorted(c.items()))))
    print('  current-valid 经证书 %d / 经 receipt %d' % (
        sum(1 for v in res.via.values() if v == 'certificate'),
        sum(1 for v in res.via.values() if v.startswith('receipt:'))))
    if a.out:
        with open(a.out, 'w') as f:
            f.write('# target\ttier\tdetail\tvia\n')
            for t in sorted(res.roots):
                tr, det = res.tier(t)
                f.write('%s\t%s\t%s\t%s\n' % (t, tr, det or '-', res.via.get(t, '-')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
