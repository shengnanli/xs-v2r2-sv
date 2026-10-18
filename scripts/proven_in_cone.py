#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""proven_in_cone.py —— 「父级证明里两侧白盒受验」的**逐条核验**名单（codex 0238 裁定 2）。

## 为什么不直接用 coverage_three_axis 的 PROVEN_IN_CONE

那一档的算法是「receipt 的 golden_closure 文件名 − 当前 worktree 的 allow 黑盒集」。
codex 0238 指出两处不成立：
  · 文件被读进来 ≠ 被例化（closure 是 source 闭包，不是 elaborated 实例图）；
  · 当前 allow ≠ 那一次 run 的 allow（allow 会改，receipt 不会）。
所以它只能当**候选**，不能当 proven。

## 这里怎么做

不建通用证据系统。名单 verif/proven_in_cone_verified.tsv 是**人工核验过、逐条写明证据**
的显式列表（每条附 receipt 路径 + sha256、impl 文件 + sha256、golden 文件 + sha256），
rewrite_coverage 只认这张表里 status=VERIFIED、且下面每一条机械复核全过的行：

  R1 receipt 已跟踪、字节 sha256 == 表里写的（换了 receipt 就得重新核验）
  R2 receipt 通过（SUCCEEDED/PASS_DEAD_REF）、非 provisional、非 dirty、top == parent
  R3 parent 本身是当前 proven（调用方传入：绿判决 + 不 STALE_IMPL）
  R4 impl_closure 里有 {path=impl_file, kind=repo, sha256=impl_sha256}，且当前仓里该文件
     字节仍是这个 sha（= 那次 run impl 侧选的就是这份可读 RTL，且现在没改过）
  R5 golden_closure 里有 golden_file 且 sha256 == golden_sha256
  R6 impl_file 里声明了 `module <module>`；module 过了 rewritten_floor（调用方传入 written 集）
  R7 那一次 run 的 black_boxes.rpt 两侧都没把 <module> 列为黑盒 design
  R8 那一次 run 的 allow（receipt.proof_config.declarations.allow 的 path@impl_commit，
     sha256 必须与 receipt 记录一致）里没有 design == <module> 的对象
  R9 那一次 run 的 fm.log 里 ref 侧加载了 golden_file、impl 侧加载了 impl_file，
     且 `Elaborating design <module>` 出现 ≥2 次（两侧都 elaborate 了它）
  R10 <module> 自己不是当前 proven（否则已在直接口径里，不许重复计）

任一条不过 → 这行**不计**，原因写进台账注释。status 不是 VERIFIED 的行（CANDIDATE）
只列出、不计。★"有 compare points 落在该实例下且在验证范围内"这一条★（例化路径、
user-match 钉点数、dead_ref 只落在 golden-only 自环上）不是机械可判的通用事实，
由核验人写进 evidence 列与 docs/lanes/ 的记录，机械复核只守住"证据没被换掉"。

父级装配里**黑盒**掉的 child 不在这里算 —— 它们由 child 自己的证明覆盖，已在直接口径里；
这里只收父级 run 里两侧白盒展开、impl 侧用的是可读 RTL 的那部分。父级 impl 侧仍用
golden 的 child（例如 Rob 的 RenameBuffer/VTypeBuffer 等）一律不收。
"""
import hashlib
import json
import pathlib
import re
import subprocess

PASS = ('SUCCEEDED', 'PASS_DEAD_REF')
COLS = ['module', 'parent_target', 'receipt', 'receipt_sha256', 'impl_file',
        'impl_sha256', 'golden_file', 'golden_sha256', 'status', 'evidence']
TABLE = pathlib.Path('verif') / 'proven_in_cone_verified.tsv'


def load_table(path):
    rows = []
    for ln in pathlib.Path(path).read_text().splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        c = ln.split('\t')
        if len(c) != len(COLS):
            raise SystemExit('proven_in_cone: %s 行列数 %d != %d：%r'
                             % (path, len(c), len(COLS), ln[:120]))
        rows.append(dict(zip(COLS, c)))
    return rows


def _sha_file(p):
    try:
        return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
    except OSError:
        return None


def _git_show(repo, commit, path):
    try:
        return subprocess.check_output(['git', '-C', str(repo), 'show',
                                        '%s:%s' % (commit, path)],
                                       stderr=subprocess.DEVNULL)
    except Exception:
        return None


def _bb_designs(rpt_text):
    """black_boxes.rpt 里两侧库列出的黑盒 design 名（行首属性列 + 名字）。"""
    out = set()
    for ln in rpt_text.splitlines():
        m = re.match(r'^([a-z*]+(?:\s+[a-z*]+)*)\s{2,}(\w+)\s*$', ln)
        if m and m.group(2) not in ('Design', 'Name'):
            out.add(m.group(2))
    return out


def verify_row(row, repo, tracked, proven, written, git_show=None):
    """返回 None（全过）或第一条不过的原因串。"""
    repo = pathlib.Path(repo)
    git_show = git_show or (lambda c, p: _git_show(repo, c, p))
    mod, par = row['module'], row['parent_target']
    rel = row['receipt']
    if rel not in tracked:
        return 'R1 receipt 未跟踪：%s' % rel
    if _sha_file(repo / rel) != row['receipt_sha256']:
        return 'R1 receipt 字节变了（sha256 != 表里登记的）'
    try:
        r = json.loads((repo / rel).read_text())
    except (OSError, ValueError) as e:
        return 'R1 receipt 读不出：%s' % e
    if r.get('verdict') not in PASS or r.get('provisional') or r.get('impl_worktree_dirty'):
        return 'R2 receipt 不是通过的正式 run（verdict=%s）' % r.get('verdict')
    if r.get('top') != par:
        return 'R2 receipt top=%s != parent %s' % (r.get('top'), par)
    if par not in proven:
        return 'R3 parent %s 不是当前 proven（无绿判决或 STALE_IMPL）' % par
    want = {'path': row['impl_file'], 'kind': 'repo', 'sha256': row['impl_sha256']}
    if not any(all(e.get(k) == v for k, v in want.items())
               for e in r.get('impl_closure') or []):
        return 'R4 impl_closure 里没有 %s(kind=repo, sha 匹配)' % row['impl_file']
    if any(pathlib.Path(e.get('path', '')).name == mod + '.sv' and e.get('kind') != 'repo'
           for e in r.get('impl_closure') or []):
        return 'R4 impl_closure 里 %s 另有 golden 来源' % mod
    if _sha_file(repo / row['impl_file']) != row['impl_sha256']:
        return 'R4 %s 当前字节已不是那次 run 的（STALE）' % row['impl_file']
    if not any(e.get('path') == row['golden_file'] and e.get('sha256') == row['golden_sha256']
               for e in r.get('golden_closure') or []):
        return 'R5 golden_closure 里没有 %s(sha 匹配)' % row['golden_file']
    src = (repo / row['impl_file']).read_text(errors='replace')
    if not re.search(r'^module\s+%s\b' % re.escape(mod), src, re.M):
        return 'R6 %s 里没有 module %s' % (row['impl_file'], mod)
    if mod not in written:
        return 'R6 %s 没过 rewritten_floor' % mod
    d = (repo / rel).parent
    try:
        bb = _bb_designs((d / 'black_boxes.rpt').read_text(errors='replace'))
    except OSError:
        return 'R7 缺 black_boxes.rpt'
    if mod in bb:
        return 'R7 那次 run 把 %s 列为黑盒' % mod
    al = ((r.get('proof_config') or {}).get('declarations') or {}).get('allow') or {}
    if al.get('path'):
        blob = git_show(r.get('impl_commit', ''), al['path'])
        if blob is None or hashlib.sha256(blob).hexdigest() != al.get('sha256'):
            return 'R8 取不回那次 run 的 allow（%s@%s）或 sha 不符' % (al['path'],
                                                                   r.get('impl_commit', '')[:12])
        objs = json.loads(blob.decode('utf-8')).get('objects', [])
        if any(o.get('design') == mod for o in objs):
            return 'R8 那次 run 的 allow 把 %s 声明为黑盒' % mod
    try:
        log = (d / 'fm.log').read_text(errors='replace')
    except OSError:
        return 'R9 缺 fm.log'
    gname = pathlib.Path(row['golden_file']).name
    if not re.search(r"^Loading verilog file '[^']*/golden-rtl/%s'" % re.escape(gname), log, re.M):
        return 'R9 fm.log 里 ref 侧没加载 %s' % gname
    if not re.search(r"^Loading verilog file '[^']*/%s'" % re.escape(row['impl_file']), log, re.M):
        return 'R9 fm.log 里 impl 侧没加载 %s' % row['impl_file']
    if len(re.findall(r'^Status:\s+Elaborating design %s\s' % re.escape(mod), log, re.M)) < 2:
        return 'R9 fm.log 里 %s 没有两侧都 elaborate' % mod
    if mod in proven:
        return 'R10 %s 已是直接 proven，不重复计' % mod
    return None


def verified(repo, proven, written, table=None, tracked=None, git_show=None):
    """→ (counted: {module: parent}, notes: [(module, status, reason)]) —— 确定性顺序。"""
    repo = pathlib.Path(repo)
    t = pathlib.Path(table) if table else repo / TABLE
    if not t.exists():
        return {}, []
    if tracked is None:
        tracked = set(subprocess.check_output(
            ['git', '-C', str(repo), 'ls-files', 'evidence/*/receipt.json'],
            universal_newlines=True).split())
    counted, notes = {}, []
    for row in load_table(t):
        if row['status'] != 'VERIFIED':
            notes.append((row['module'], row['status'], '非 VERIFIED，只列不计'))
            continue
        why = verify_row(row, repo, tracked, proven, written, git_show)
        if why:
            notes.append((row['module'], 'REJECTED', why))
        elif row['module'] in counted:
            notes.append((row['module'], 'REJECTED', '重复行'))
        else:
            counted[row['module']] = row['parent_target']
            notes.append((row['module'], 'COUNTED', 'R1-R10 全过（parent=%s）'
                          % row['parent_target']))
    return counted, notes
