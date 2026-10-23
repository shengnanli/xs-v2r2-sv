#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xstile_proof_tree.py —— 从 XSTile 证书出发，递归展开**本次实际证明依赖树**（codex 0244 层次化证明链）。

## 收尾判据（codex 0244）

* 有效父级白盒证明覆盖内部实现 ⇒ 承认其「父配置内集成证明」（不称子模块独立证明）。
* ★黑盒逻辑边界★必须有与该实例实际实现/配置匹配的当前有效子证明，沿依赖递归闭合。
* 不能以两侧同读 golden 代替未证明的实际重写件：impl 侧直接读 golden 的模块（impl_golden 边）
  必须是登记存储模型，或自身持有 current-valid 证书。

## 边（全部来自证书本身绑定的输入，从 commit 读，不读工作树）

  root              XSTile 证书
  blackbox-child    证书 proof_config.declarations.allow 里 class=green_child 的对象
                    （design → child_target + certificate_sha256）。逐个递归。
  blackbox-memory   allow 里 class ∈ {vendor_macro, APPROVED_MEMORY_MACRO_MODEL, disabled_empty_module}
                    的对称黑盒（厂商宏 / 已批准存储模型 / 禁用空模块）。叶子，不递归。
  impl_golden       证书 input_closure.impl 里 kind=golden 的条目（impl 侧直接读 golden）。
                    登记存储模型（mc_memory_registry / 本证书 allow 声明的 memory 模型）→ 叶子；
                    否则按 FM target 证书递归。
  mc-chain          impl_golden 存储模型在 G1 里的例化子链（如 array_9 → array_9_ext），随该边一起判。
  whitebox-in-parent  父证书 ref 侧 golden 闭包里、从父 variant 例化可达且未被 allow 切成黑盒的模块
                    （proof_currency.reach，与 WB2 同一函数）。由父证明白盒覆盖，不递归、不要求独立证书；
                    若该模块恰有证书，cv 列仅作参考。

## 判据（★不另写一份★）

  root                proof_certificate.validate_certificate_current
  blackbox-child      proof_certificate.validate_child_certificate（与父级 green_child 校验完全同一调用，含 sha 比对）
  impl_golden         ① 父证书只保留这一条 golden 条目后调用 proof_certificate.validate_impl_golden_certified
                        （逐条给出该边自身的结论；cv-recur lane 合入后它会递归核对子证书 current-valid，这里自动生效）；
                      ② 若是 FM target 且有证书，再对子证书本身调用 validate_certificate_current（节点 cv）。
  whitebox / memory   不单独判；覆盖成立条件 = 父节点 current-valid（父节点自己是一行，失败在父那行记阻塞）。

## 输出

TSV（stdout 或 --out）：target / edge / parent / depth / design / cert / cv / coverage / blocking / incore /
delivered / note。delivered = 交付一致性（证明的实现 == docs/xstile_srcmap.tsv 的交付源，见 delivered_pass）。
--summary 打印统计、阻塞行与「交付件无证明绑定」列表；退出码 0 ⟺ 两者皆空。--check-list 对一份名单（逐行 target）给出「是否在树内 / 怎么在树内」。
docs/xstile_proof_tree.tsv 视为派生表，lane 不提交。

用法:
    TMPDIR=... python3 scripts/xstile_proof_tree.py --summary --out $TMPDIR/xstile_proof_tree.tsv
    python3 scripts/xstile_proof_tree.py --check-list names.txt
"""
import collections
import copy
import json
import os
import pathlib
import re
import sys

_HERE = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(os.environ.get('XSSV_HOME') or _HERE.parent)
G1 = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical'))

MEMORY_BB_CLASSES = {'vendor_macro': 'MC_MODEL(vendor_macro)',
                     'APPROVED_MEMORY_MACRO_MODEL': 'MC_MODEL(approved_memory)',
                     'disabled_empty_module': 'EMPTY_MODULE'}
COLS = ('target', 'edge', 'parent', 'depth', 'design', 'cert', 'cv', 'coverage', 'blocking', 'incore', 'delivered',
        'note')


class Node(object):
    __slots__ = COLS

    def __init__(self, **kw):
        for c in COLS:
            setattr(self, c, kw.get(c, '-'))

    def row(self):
        return '\t'.join(str(getattr(self, c)).replace('\t', ' ').replace('\n', ' ') for c in COLS)


# ----------------------------------------------------------------------------
# 环境：真仓用 RealEnv（全部委托现有判据）；测试注入 Fake
# ----------------------------------------------------------------------------
class RealEnv(object):
    def __init__(self, commit='HEAD', repo=None, g1=None):
        self.repo_path = pathlib.Path(repo or REPO)
        self.g1 = pathlib.Path(g1 or G1)
        os.environ.setdefault('XSSV_HOME', str(self.repo_path))
        os.environ.setdefault('G1_CANONICAL', str(self.g1))
        sys.path.insert(0, str(_HERE))
        import fm_verdict as fv
        import proof_certificate as PC
        import proof_currency as CUR
        self.PC, self.CUR = PC, CUR
        ctx, err = fv._cert_ctx(commit)
        if err:
            raise SystemExit('xstile_proof_tree: cert ctx 失败（fail-closed）：%s' % err)
        self.repo = CUR.BatchRepo(ctx['repo'])
        self.commit, self.policy = ctx['commit'], ctx['policy']
        self.targets, self.unresolved = ctx['targets'], ctx['unresolved']
        self.g1s = str(ctx['g1'])
        self.canon = (self.g1 / 'CANONICAL_ID.txt').read_text().strip()
        mc, merr = PC.load_mc_context(self.repo, self.commit)
        if merr:
            raise SystemExit('xstile_proof_tree: MC 登记表读取失败：%s' % merr)
        self.mc_reg = set(mc['reg'])
        self.defs, self.inst = golden_graph_sv_v(CUR, self.g1)
        blob = self.repo.show(self.commit, 'docs/xstile_closure.tsv')
        self.tile = set()
        for ln in (blob.decode('utf-8', 'replace').splitlines() if blob else []):
            c = ln.split('\t')
            if not ln.startswith('#') and len(c) >= 2 and c[1].isdigit():
                self.tile.add(c[0])
        self._cert = {}
        self._reach = {}
        blob = self.repo.show(self.commit, 'docs/xstile_srcmap.tsv')
        self.srcmap = None
        if blob is not None:
            self.srcmap = {}
            for ln in blob.decode('utf-8', 'replace').splitlines():
                c = ln.split('\t')
                if ln.startswith('#') or len(c) < 4 or c[0] == 'module':
                    continue
                self.srcmap[c[0]] = (c[1], c[2], c[3])

    # -- 读取 --
    def cert(self, t):
        if t not in self._cert:
            self._cert[t] = self.PC.load_certificate(self.repo, self.commit, t)
        return self._cert[t]

    def allow(self, doc):
        a, err = self.PC._allow_doc_of(self.repo, self.commit, doc)
        return a or {}, err

    def is_target(self, t):
        return t in self.targets

    def is_mc(self, mod):
        return mod in self.mc_reg

    def mc_chain(self, mod):
        """MC 模型在 G1 里的例化子链（*_ext 等）。其字节/端口/链由 MC 登记表复算覆盖（check_golden_entry）。"""
        out, st = [], list(self.inst.get(mod, ()))
        while st:
            m = st.pop()
            if m in out:
                continue
            out.append(m)
            st.extend(self.inst.get(m, ()))
        return sorted(out)

    def delivered(self, t):
        """交付源（docs/xstile_srcmap.tsv @commit）：(kind, source, sha) / None（表里没有）/ 'n/a'（无表）。"""
        if self.srcmap is None:
            return 'n/a'
        return self.srcmap.get(t)

    def delivered_all(self):
        return dict(self.srcmap or {})

    def has_outputs(self, path, module):
        import xstile_srcmap as XS
        blob = self.repo.show(self.commit, path)
        if blob is None:
            return True
        text = XS.COMMENT_RE.sub(' ', blob.decode('utf-8', 'replace'))
        mm = re.search(r'^\s*module\s+%s\b' % re.escape(module), text, re.M)
        if not mm:
            return True
        hdr = text[mm.end():text.find(');', mm.end())]
        return re.search(r'\boutput\b', hdr) is not None

    def incore(self, t):
        return t in self.tile

    def whitebox(self, doc, cut):
        gfiles = {os.path.basename(e['path']) for e in doc['input_closure']['golden']}
        var = doc['variant']
        seen = self.CUR.reach(var, self.inst, gfiles, self.defs, cut)
        out = []
        for m in sorted(seen - {var}):
            if m in cut:
                continue
            out.append((m, self.defs.get(m) in gfiles))
        return out

    def impl_reach(self, doc, cut, through_golden=False):
        """证明 impl 侧实际例化闭包：{module: 定义文件路径}。从 doc.variant 出发，只在该证明 impl 闭包
        （repo 文件按 commit 字节、golden 条目按 G1）定义的模块里走；allow 黑盒（cut）不下钻、不计入。
        例化识别复用 xstile_srcmap 的同一组正则（含宏实参例化）。impl 侧挂的 golden 模块记为叶子、不下钻：
        交付件里它由自己的重写件替代（那一份由它自己的证书绑定），golden 体内的子例化不属于交付。"""
        import xstile_srcmap as XS
        key = (doc.get('target'), doc.get('result_sha256'), doc.get('input_closure', {}).get('impl_sha256'),
               through_golden)
        if key in self._reach:
            return self._reach[key]
        defs = {}
        for e in doc['input_closure']['impl']:
            path = e.get('path') or ''
            if e.get('kind') == 'repo':
                blob = self.repo.show(self.commit, path)
            elif e.get('kind') == 'golden':
                f = self.g1 / 'golden-rtl' / os.path.basename(path)
                blob = f.read_bytes() if f.is_file() else None
            else:
                continue
            if blob is None:
                continue
            text = XS.COMMENT_RE.sub(' ', blob.decode('utf-8', 'replace'))
            for m in XS.MODULE_RE.findall(text):
                defs.setdefault(m, (path, text))
        known = set(defs)
        top = doc['variant']
        out, st = {}, [top]
        while st:
            m = st.pop()
            if m in out or m not in defs or (m in cut and m != top):
                continue
            path, text = defs[m]
            out[m] = path
            if m != top and path.startswith('golden-rtl/') and not through_golden:
                continue            # impl 侧挂的 golden 模块：交付时由其自身（重写件 + 自身证书）替代，不下钻
            body = XS._module_body(text, m)
            kids = {k for k in XS.INST_RE.findall(body) if k in known and k != m}
            for mc in XS.MACRO_CALL_RE.finditer(body):
                kids |= {k for k in XS.WORD_RE.findall(XS._balanced(body, mc.end() - 1)) if k in known and k != m}
            st.extend(kids)
        self._reach[key] = out
        return out

    # -- 判据（全部委托） --
    def cv_cert(self, t, doc):
        return self.PC.validate_certificate_current(
            self.repo, self.commit, t, doc, expect_canonical=self.canon, policy=self.policy,
            fm_targets=self.targets, fm_targets_unresolved=self.unresolved, g1_root=self.g1s)

    def cv_child(self, t, declared_sha):
        return self.PC.validate_child_certificate(
            self.repo, self.commit, t, declared_sha, expect_canonical=self.canon, policy=self.policy,
            fm_targets=self.targets, fm_targets_unresolved=self.unresolved, g1_root=self.g1s)

    def impl_golden_edge(self, parent, doc, entry):
        """父证书只保留这一条 impl golden 条目，交给 validate_impl_golden_certified 判这一条边。"""
        d = copy.deepcopy(doc)
        d['input_closure']['impl'] = [e for e in doc['input_closure']['impl'] if e.get('kind') != 'golden'] + [entry]
        return self.PC.validate_impl_golden_certified(
            self.repo, self.commit, parent, d, policy=self.policy, fm_targets=self.targets,
            fm_targets_unresolved=self.unresolved, g1_root=self.g1s)


def golden_graph_sv_v(CUR, g1):
    """proof_currency.golden_graph（只扫 *.sv）再补上 G1 里的 *.v 定义（厂商/行为模型叶子，
    如 PrintCommitIDModule.v、array_9_ext.v），否则这些叶子在树里看不见。用同一组正则。"""
    defs, inst = CUR.golden_graph(g1)
    raw = {}
    for f in sorted((pathlib.Path(g1) / 'golden-rtl').glob('*.v')):
        cur = None
        for ln in f.read_text(errors='replace').splitlines():
            m = CUR._MOD.match(ln)
            if m:
                cur = m.group(1)
                if cur not in defs:
                    defs[cur] = f.name
                    raw[cur] = set()
                else:
                    cur = None
                continue
            if cur is None:
                continue
            if ln.strip().startswith('endmodule'):
                cur = None
                continue
            m = CUR._INST.match(ln)
            if m:
                raw[cur].add(m.group(1))
    known = set(defs)
    for k, v in raw.items():
        inst[k] = v & known
    # 已知模块里例化了 .v 模块的，补边（golden_graph 当初按 known 过滤掉了）
    for f in sorted((pathlib.Path(g1) / 'golden-rtl').glob('*.sv')):
        cur = None
        for ln in f.read_text(errors='replace').splitlines():
            m = CUR._MOD.match(ln)
            if m:
                cur = m.group(1)
                continue
            if cur is None:
                continue
            m = CUR._INST.match(ln)
            if m and m.group(1) in raw:
                inst.setdefault(cur, set()).add(m.group(1))
    return defs, inst


def delivered_pass(env, nodes, proofs):
    """「证明的实现 == 交付的实现」（codex 0244 条件 2：子证明须与该实例**实际实现**匹配）。

    交付源 = docs/xstile_srcmap.tsv @commit（rtl/ 优先选源；golden 只许登记存储模型）。
    impl_reach(P) = 证明 P 的 impl 侧从 P.variant 起实际例化的模块 → 定义文件。

      root / blackbox-child / impl_golden(FM)  交付源 == impl_reach(自己的证明)[自己]
      impl_golden(FM)                          另注：父证明 impl 侧是否真例化它（否 = 宽 filelist 假依赖）
      whitebox-in-parent                       父证明 impl 侧例化了它 ⇒ 交付源 == 父 impl_reach 里的定义文件；
                                               父 impl 侧没例化它 ⇒ flattened（golden 层次被重写件内联，非阻塞）
      存储（impl_golden MC / mc-chain / blackbox-memory）  交付 kind=MEMORY_MODEL（impl_golden 边再比 sha）
      blackbox-memory(disabled_empty_module)   交付为 RTL 且模块无 output 端口
    另做**全局闭合**：交付源表每个 RTL 模块，必须被树里某个 current-valid 证明在 impl 侧以同一文件例化；
    每个 MEMORY_MODEL 行必须是树里某个通过的存储节点。不满足的进 build_tree.unbound（阻塞）。"""
    build_tree.unbound = []
    if env.delivered('XSTile') == 'n/a':
        for n in nodes:
            n.delivered = 'n/a(no_srcmap)'
        return
    reach = {}

    def R(t):
        if t not in reach:
            doc, _ok, cut = proofs[t]
            reach[t] = env.impl_reach(doc, cut)
        return reach[t]

    def bad(n, txt):
        n.delivered = txt
        n.blocking = 'yes'

    for n in nodes:
        d = env.delivered(n.target)
        mem = n.edge in ('mc-chain', 'blackbox-memory') or (n.edge == 'impl_golden' and n.cert == '-')
        if n.edge == 'blackbox-memory' and n.coverage == 'EMPTY_MODULE':
            if d is None:
                n.delivered = 'not_delivered'
            elif d[0] != 'RTL':
                bad(n, 'empty_module_delivered_as_%s' % d[0])
            elif env.has_outputs(d[1], n.target):
                bad(n, 'empty_module_delivered_with_outputs:%s' % d[1])
            else:
                n.delivered = 'ok:input_only_shell:%s' % d[1]
            continue
        if mem:
            want = n.delivered if (n.edge == 'impl_golden' and n.delivered not in ('-', None)) else None
            if d is None:
                n.delivered = 'not_in_srcmap(memory_leaf)'
            elif d[0] != 'MEMORY_MODEL':
                bad(n, 'memory_delivered_as_%s:%s' % (d[0], d[1]))
            elif want and d[2] != want:
                bad(n, 'memory_sha_mismatch:%s' % d[1])
            else:
                n.delivered = 'ok:MEMORY_MODEL:%s' % os.path.basename(d[1])
            continue
        if n.edge == 'whitebox-in-parent':
            r = R(n.parent).get(n.target) if n.parent in proofs else None
            if r is None:
                n.delivered = 'flattened_in_parent_impl'
            elif d is None:
                bad(n, 'parent_impl_instantiates_but_not_delivered:%s' % r)
            elif d[1] != r:
                bad(n, 'src_mismatch:delivered=%s,parent_impl=%s' % (d[1], r))
            else:
                n.delivered = 'ok:%s' % r
            continue
        # root / blackbox-child / impl_golden(FM target)
        pre = ''
        if n.edge == 'impl_golden':
            if n.parent in proofs and n.target in R(n.parent):
                pre = 'parent_rtl_instantiates;'
            elif n.parent in proofs and n.target in env.impl_reach(proofs[n.parent][0], proofs[n.parent][2], True):
                pre = 'via_golden_impl_module;'
            else:
                pre = 'unused_in_parent_impl(false_dep);'
        if n.target not in proofs:
            if d is None:
                n.delivered = pre + 'not_delivered'
            else:
                bad(n, pre + 'no_expanded_proof:%s' % d[1])
            continue
        r = R(n.target).get(n.target)
        if d is None:
            if pre.startswith('parent_rtl_instantiates'):
                bad(n, pre + 'not_delivered')
            else:
                n.delivered = pre + 'not_delivered'
        elif d[1] != r:
            bad(n, pre + 'src_mismatch:delivered=%s,own_proof=%s' % (d[1], r))
        else:
            n.delivered = pre + 'ok:%s' % r
    # 全局闭合
    bound = collections.defaultdict(set)
    for t, (_doc, ok, _cut) in proofs.items():
        if ok:
            for m, f in R(t).items():
                bound[m].add(f)
    memok = {n.target for n in nodes if str(n.delivered).startswith('ok:MEMORY_MODEL')}
    # disabled_empty_module：交付件是无 output 的输入空壳（上面已核），无可观测行为，按其黑盒声明接受
    empty_ok = {(n.target, n.delivered.split(':', 2)[2]) for n in nodes
                if str(n.delivered).startswith('ok:input_only_shell:')}
    unbound = []
    for m, (kind, src, _sha) in sorted(env.delivered_all().items()):
        if kind == 'RTL' and (m, src) in empty_ok:
            continue
        if kind == 'RTL' and src not in bound.get(m, ()):
            unbound.append((m, kind, src, ','.join(sorted(bound.get(m, ()))) or '-'))
        elif kind == 'MEMORY_MODEL' and m not in memok:
            unbound.append((m, kind, src, '-'))
    build_tree.unbound = unbound


def _short(r):
    return 'TRUE' if r is True else str(r)


def build_tree(env, root='XSTile'):
    """BFS。每个 target 只展开一次（首见，深度最小）；重复出现照样出一行（note=dup）。"""
    nodes = []
    proofs = {}                 # 树里每个被展开的证明：target -> (doc, current_valid, cut)
    cvmemo = {}
    expanded = set()
    q = collections.deque()

    def cert_cv(t, doc):
        if t not in cvmemo:
            cvmemo[t] = env.cv_cert(t, doc)
        return cvmemo[t]

    doc, _sha, err = env.cert(root)
    if err:
        nodes.append(Node(target=root, edge='root', parent='-', depth=0, cert='no', cv=err,
                          coverage='NONE', blocking='yes', incore='yes' if env.incore(root) else 'no'))
        return nodes
    r = cert_cv(root, doc)
    nodes.append(Node(target=root, edge='root', parent='-', depth=0, design=root, cert='yes', cv=_short(r),
                      coverage='DIRECT' if r is True else 'NONE', blocking='no' if r is True else 'yes',
                      incore='yes' if env.incore(root) else 'no', note=doc.get('proof_mode', '-')))
    q.append((root, doc, 0, r is True))
    while q:
        p, pdoc, dep, pok = q.popleft()
        if p in expanded:
            continue
        expanded.add(p)
        allow, aerr = env.allow(pdoc)
        cut = set()
        bb = collections.OrderedDict()
        for o in allow.get('objects') or []:
            cut.add(o.get('design'))
        proofs[p] = (pdoc, pok, set(cut))
        for o in allow.get('objects') or []:
            if o.get('side') != 'r':
                continue
            key = (o.get('class'), o.get('design'), o.get('child_target'), o.get('certificate_sha256'))
            bb.setdefault(key, 0)
            bb[key] += 1
        # 1. blackbox-child / blackbox-memory
        for (cls, design, ct, csha), n in bb.items():
            inst = 'x%d' % n
            if cls == 'green_child':
                t = ct or design
                cdoc, _s, cerr = env.cert(t)
                key = ('child', t, csha)
                if key not in cvmemo:
                    cvmemo[key] = env.cv_child(t, csha)
                r = cvmemo[key]
                ok = r is True
                nodes.append(Node(target=t, edge='blackbox-child', parent=p, depth=dep + 1, design=design,
                                  cert='no' if cerr else 'yes', cv=_short(r),
                                  coverage='DIRECT' if ok else 'NONE', blocking='no' if ok else 'yes',
                                  incore='yes' if env.incore(t) else 'no',
                                  note='%s;%s%s' % (inst, (cdoc or {}).get('proof_mode', '-'),
                                                    ';dup' if t in expanded else '')))
                if cdoc is not None:
                    q.append((t, cdoc, dep + 1, ok))
            else:
                cov = MEMORY_BB_CLASSES.get(cls, 'UNKNOWN_BLACKBOX_CLASS(%s)' % cls)
                bad = cov.startswith('UNKNOWN')
                nodes.append(Node(target=design, edge='blackbox-memory', parent=p, depth=dep + 1, design=design,
                                  cert='-', cv='via_parent' if not bad else 'unknown_class',
                                  coverage=cov, blocking='yes' if bad else 'no',
                                  incore='yes' if env.incore(design) else 'no', note='%s;class=%s' % (inst, cls)))
        # 2. impl_golden
        seen_ig = set()
        for e in pdoc['input_closure']['impl']:
            if e.get('kind') != 'golden':
                continue
            mod = os.path.basename(e.get('path') or '')[:-3]
            if mod in seen_ig:
                continue
            seen_ig.add(mod)
            er = env.impl_golden_edge(p, pdoc, e)
            declared_mem = any(o.get('design') == mod and o.get('class') == 'APPROVED_MEMORY_MACRO_MODEL'
                               for o in allow.get('objects') or [])
            if declared_mem or env.is_mc(mod):
                ok = er is True
                nodes.append(Node(target=mod, edge='impl_golden', parent=p, depth=dep + 1, design=mod, cert='-',
                                  cv=_short(er), coverage='MC_MODEL' if ok else 'NONE',
                                  blocking='no' if ok else 'yes', incore='yes' if env.incore(mod) else 'no',
                                  note='approved_memory' if declared_mem else 'mc_registry'))
                nodes[-1].delivered = e.get('sha256')        # 暂存，post-pass 覆写
                for c in env.mc_chain(mod):
                    nodes.append(Node(target=c, edge='mc-chain', parent=mod, depth=dep + 2, design=c, cert='-',
                                      cv='via_parent_edge', coverage='MC_MODEL' if ok else 'NONE',
                                      blocking='no' if ok else 'yes', incore='yes' if env.incore(c) else 'no',
                                      note='registry_child_chain'))
                continue
            cdoc, _s, cerr = env.cert(mod) if env.is_target(mod) else (None, None, 'not_fm_target')
            nr = cert_cv(mod, cdoc) if cdoc is not None else (cerr or 'no_certificate')
            ok = er is True and nr is True
            cv = _short(nr) if er is True else ('edge:%s' % _short(er) if nr is True
                                                else 'edge:%s | node:%s' % (_short(er), _short(nr)))
            nodes.append(Node(target=mod, edge='impl_golden', parent=p, depth=dep + 1, design=mod,
                              cert='yes' if cdoc is not None else 'no', cv=cv,
                              coverage='DIRECT' if ok else 'NONE', blocking='no' if ok else 'yes',
                              incore='yes' if env.incore(mod) else 'no',
                              note=('fm_target' if env.is_target(mod) else 'not_fm_target')
                              + (';dup' if mod in expanded else '')))
            if cdoc is not None:
                q.append((mod, cdoc, dep + 1, ok))
        # 3. whitebox-in-parent
        # impl 侧直接读 golden 的模块（及其子链）已由 impl_golden / mc-chain 边判，白盒可达性在此截断
        for m, resolved in env.whitebox(pdoc, cut | seen_ig):
            cdoc, _s, cerr = env.cert(m) if env.is_target(m) else (None, None, 'x')
            info = _short(cert_cv(m, cdoc)) if cdoc is not None else '-'
            if not resolved:
                cov, blk, note = 'WB_UNRESOLVED', 'yes', 'reached_but_not_in_parent_golden_closure'
            else:
                cov = 'WB_IN_PARENT' if pok else 'WB_IN_PARENT(parent_not_current)'
                blk, note = 'no', 'own_cert_info_only' if cdoc is not None else '-'
            nodes.append(Node(target=m, edge='whitebox-in-parent', parent=p, depth=dep + 1, design=m,
                              cert='yes' if cdoc is not None else 'no', cv=info, coverage=cov, blocking=blk,
                              incore='yes' if env.incore(m) else 'no', note=note))
    build_tree.proofs = proofs
    delivered_pass(env, nodes, proofs)
    return nodes


def summarize(nodes):
    """统计（按唯一 target 取最好覆盖：DIRECT > MC > WB > NONE）+ 阻塞行。"""
    rank = {'DIRECT': 0, 'MC_MODEL': 1, 'MC_MODEL(vendor_macro)': 1, 'MC_MODEL(approved_memory)': 1,
            'EMPTY_MODULE': 1, 'WB_IN_PARENT': 2}
    best = {}
    for n in nodes:
        k = rank.get(n.coverage, 9)
        if n.target not in best or k < best[n.target][0]:
            best[n.target] = (k, n.coverage)
    s = {
        'rows': len(nodes),
        'unique_targets': len(best),
        'edges': dict(collections.Counter(n.edge for n in nodes)),
        'coverage_rows': dict(collections.Counter(n.coverage for n in nodes)),
        'coverage_unique': dict(collections.Counter(v[1] for v in best.values())),
        'cert_nodes': len({n.target for n in nodes if n.edge in ('root', 'blackbox-child', 'impl_golden')
                           and n.cert == 'yes'}),
    }
    blockers = [n for n in nodes if n.blocking == 'yes']
    return s, blockers


def where(nodes, name):
    hits = [n for n in nodes if n.target == name]
    if not hits:
        return 'NOT_IN_TREE'
    return ';'.join(sorted({'%s<-%s:%s' % (n.edge, n.parent, n.coverage) for n in hits}))


def main():
    import argparse
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--commit', default='HEAD')
    ap.add_argument('--root', default='XSTile')
    ap.add_argument('--out')
    ap.add_argument('--summary', action='store_true')
    ap.add_argument('--check-list', help='逐行 target 名单：输出是否在树内')
    a = ap.parse_args()
    env = RealEnv(a.commit)
    nodes = build_tree(env, a.root)
    text = '# xstile_proof_tree @ %s root=%s（派生表，不入库）\n# %s\n' % (env.commit, a.root, '\t'.join(COLS))
    text += ''.join(n.row() + '\n' for n in nodes)
    if a.out:
        pathlib.Path(a.out).write_text(text)
    elif not a.summary and not a.check_list:
        sys.stdout.write(text)
    unbound = getattr(build_tree, 'unbound', [])
    if a.summary:
        s, blockers = summarize(nodes)
        s['delivered_rows'] = dict(collections.Counter(str(n.delivered).split(':')[0] for n in nodes))
        s['delivered_unbound'] = len(unbound)
        s['delivered_srcmap_rows'] = len(env.delivered_all())
        print(json.dumps(s, ensure_ascii=False, indent=1, sort_keys=True))
        print('# blocking rows: %d' % len(blockers))
        for n in blockers:
            print(n.row())
        print('# delivered-but-unbound (交付源表里、树中无 current-valid 证明以同一文件例化): %d' % len(unbound))
        for u in unbound:
            print('UNBOUND\t' + '\t'.join(u))
    if a.check_list:
        for ln in pathlib.Path(a.check_list).read_text().splitlines():
            t = ln.split('#')[0].strip()
            if t:
                print('%s\t%s\t%s' % (t, 'incore' if env.incore(t) else 'outcore', where(nodes, t)))
    _s, blockers = summarize(nodes)
    return 1 if (blockers or unbound) else 0


if __name__ == '__main__':
    sys.exit(main())
