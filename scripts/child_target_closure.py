#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""child_target_closure.py —— A 类边界 child 的「有没有 FM target / 证明到哪一步」。

## 它回答哪个问题

`verif/allow_gen/classification.tsv` 里每个 A 类目标都列了它的 **boundary_designs**
（assembly 边界上的 child）。对每一个 child 必须先回答两件事，才能谈 allow 声明：

  1. 它**是不是 FM target**？不是 → 它永远拿不到证书，只能改走「两侧 inline
     elaborate」或「新建 AUX leaf target 并正式证明」，**不得用 allow 绕过**。
  2. 它**有没有 tracked 证书**？没有 → `UNVERIFIED`。
     ★「是 target」和「已证明」是两件事★，把它们混成一个 NO 正是下面这起事故。

## 本文件为什么存在（codex 0153 D70）

`verif/allow_gen/classification.tsv` 的 blocker 一栏是**人写的散文**，写的时候用的
是一份坏解析器的结论。实测（见 `docs/fm_target_universe_defect_diff.tsv`）：

    ICacheMetaArray  blocker: "MbistPipeIcacheTag 根本不是任何 UT 的 FM target
                               ⇒ child 不闭合（永远无法变绿）"
    ICache           blocker: "ICacheMainPipe/ICacheMissUnit/IPrefetchPipe 不是 FM target"

两条都**错**：

    MbistPipeIcacheTag  是 FM target（ut=MbistPipe，verif/ut/MbistPipe/Makefile:31
                        `FM_VARIANTS := $(VARIANTS)`，坏解析器匹配不上 `:=`）
    ICacheMissUnit      是 FM target（ut=ICacheMissUnit，Makefile:59 就是字面量）

于是全仓「没有 FM target 的 child」被记成 **11 个**，真实是 **9 个**。

D70 的裁定：**重新生成，不手改那两行当最终来源**。所以：

  * 本脚本生成 `docs/child_target_closure.tsv` —— 这才是 child 闭合性的**最终来源**，
    每一行都由 make 权威求值 + tracked 证书机械推出；
  * `--audit` 把 classification.tsv 里所有「X 不是 FM target」式的散文断言拿去和
    权威结论对账，**对不上就 FAIL**。散文从此是被机器看着的，不再能自己漂。

## 判据

  is_fm_target   scripts/fm_target_universe.py（engine=both：make 权威 + 正则交叉校验）
  proof_status   scripts/proof_status.py（只认 tracked verif/proof_certificates/*.json）

## 退出码

  0  一致 / 生成成功
  1  --audit 抓到假断言，或 --check 幂等不一致
  2  输入缺失、make 求值失败、两引擎分歧（fail-closed）

用法:
    python3 scripts/child_target_closure.py --repo . --tsv docs/child_target_closure.tsv
    python3 scripts/child_target_closure.py --repo . --audit
    python3 scripts/child_target_closure.py --repo . --check
"""
from __future__ import print_function

import argparse
import hashlib
import os
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import fm_target_universe as FTU                                   # noqa: E402
import proof_status as PS                                          # noqa: E402

CLASSIFICATION = 'verif/allow_gen/classification.tsv'
OUT_TSV = 'docs/child_target_closure.tsv'

#: boundary_designs 一栏的写法不统一，三种都出现过：
#:   `MbistPipeIcacheTag(1) SplittedSRAMTemplate(1)`     名字(实例数)
#:   `ref:array_8_ext(8) / impl:array_8(8)`              两侧不对称时分别列
#:   `ICacheCtrlUnit ICacheDataArray ...`                裸名字
#: 统一抽成裸设计名。`ref:`/`impl:`/`/` 是标注不是名字，去掉。
_DESIGN = re.compile(r'(?:^|[\s/])(?:ref:|impl:)?([A-Za-z_]\w*)(?:\((\d+)\))?')

#: 散文里的「X 不是 FM target」。三种写法都在 classification.tsv 里出现过：
#:   "MbistPipeIcacheTag 根本不是任何 UT 的 FM target"
#:   "ICacheMainPipe/ICacheMissUnit/IPrefetchPipe 不是 FM target"
#:   "三个 child 全都不是 FM target"（不点名 → 落到该行的全部 child 上）
_CLAIM_NAMED = re.compile(r'([A-Za-z_][\w/]*)\s*(?:根本)?不是(?:任何 UT 的)?\s*FM target')
_CLAIM_ALL = re.compile(r'(?:全都|都)不是\s*FM target|child 不是\s*FM target')

HDR = [
    '# A 类边界 child 的 FM target 闭合性与证明状态',
    '#   （scripts/child_target_closure.py 生成；禁止手工编辑）',
    '# ★这是 child 闭合性的最终来源★（codex 0153 D70）。',
    '#   verif/allow_gen/classification.tsv 的 blocker 是人写的散文，本表是机器结论；',
    '#   `--audit` 会把散文里每一句「X 不是 FM target」拿来和本表对账，对不上就 FAIL。',
    '# is_fm_target : scripts/fm_target_universe.py，engine=both（make 权威 + 正则交叉校验）',
    '# proof_status : scripts/proof_status.py，只认 tracked verif/proof_certificates/*.json',
    '# ★「是 target」≠「已证明」★：有 target 但没证书 = HAS_TARGET_UNVERIFIED，',
    '#   它**可以**通过 clean official rerun + 出证书变绿；而 NO_FM_TARGET 是结构性',
    '#   不闭合，只能改走两侧 inline elaborate 或新建 AUX leaf target。',
    '# boundary_class: A1=厂商宏（冻结 registry 批准即可，本就无需自己的 FM target）',
    '#                 A2=green_child 候选（**必须**是 FM target，否则结构性不闭合）',
    '# ★D70 盯的那个数是 A2 且无 target 的 child 数★（本轮 11 → 9）。',
    '# makefiles_sha256 = 所有被读入的 verif/ut/*/Makefile + scripts/ut_common.mk 的字节摘要。',
    '#   刻意不写 commit：artifact 自己被提交后 commit 就变了，--check 会永远失败。',
    '# child\tboundary_class\tis_fm_target\tut_dirs\tproof_status\tverdict\treferenced_by',
]

V_NO_TARGET = 'NO_FM_TARGET'
V_UNVERIFIED = 'HAS_TARGET_UNVERIFIED'
V_VERIFIED = 'HAS_TARGET_VERIFIED'
V_CERT_BAD = 'HAS_TARGET_CERT_PROBLEM'


def _rev(repo, rev):
    p = subprocess.run(['git', 'rev-parse', rev + '^{commit}'], cwd=str(repo),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise SystemExit('无法解析 commit %r（repo=%s）' % (rev, repo))
    return p.stdout.decode().strip()


def parse_designs(cell):
    """从 boundary_designs 单元格里抽出设计名（去重，保序）。"""
    out = []
    for m in _DESIGN.finditer(cell or ''):
        n = m.group(1)
        if n and n not in out:
            out.append(n)
    return out


def read_classification(path):
    """[(target, boundary_designs 原文, [child…], blocker)]。"""
    p = pathlib.Path(path)
    if not p.exists():
        raise SystemExit('分类表不存在（fail-closed）: %s' % p)
    rows, hdr = [], None
    for ln in p.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        if hdr is None:
            hdr = f
            continue
        cell = f[4] if len(f) > 4 else ''
        klass = f[5] if len(f) > 5 else '?'
        blocker = f[7] if len(f) > 7 else ''
        rows.append((f[0], cell, parse_designs(cell), blocker, klass))
    if not rows:
        raise SystemExit('分类表一行数据都没有（空表不算通过）: %s' % p)
    return rows


def build(repo, commit):
    tmap, unresolved = FTU.targets_at(str(repo), commit)
    if unresolved:
        raise SystemExit('FM target 全集未完全展开，拒绝据此下 NOT_FM_TARGET 结论'
                         '（fail-closed）: %s' % ' '.join(unresolved[:5]))
    pmap = PS.status_map(repo)
    rows = read_classification(pathlib.Path(repo) / CLASSIFICATION)

    refs, kclass = {}, {}
    for tgt, _cell, kids, _bl, klass in rows:
        for k in kids:
            refs.setdefault(k, []).append(tgt)
            # A1=厂商宏边界（冻结 registry 批准即可，本就不需要自己的 FM target）
            # A2=green_child 候选（**必须**是 FM target 才谈得上闭合）
            kclass.setdefault(k, set()).add('A2' if klass.startswith('A2') else
                                            ('A1' if klass.startswith('A1') else klass))

    out = []
    for child in sorted(refs):
        is_t = child in tmap
        pst, _pnote = PS.status_of(pmap, child)
        if not is_t:
            verdict = V_NO_TARGET
        elif pst == PS.VERIFIED:
            verdict = V_VERIFIED
        elif pst == PS.UNVERIFIED:
            verdict = V_UNVERIFIED
        else:
            verdict = V_CERT_BAD
        out.append((child, ','.join(sorted(kclass[child])),
                    'YES' if is_t else 'NO',
                    ','.join(sorted(tmap.get(child, []))) or '-',
                    pst, verdict, ','.join(refs[child])))
    return out, rows, tmap


def render(rows, digest, tmap):
    n_no = sum(1 for r in rows if r[5] == V_NO_TARGET)
    n_a2_no = sum(1 for r in rows if r[5] == V_NO_TARGET and 'A2' in r[1])
    lines = list(HDR)
    lines.insert(len(HDR) - 1,
                 '# makefiles_sha256=%s  FM target 全集=%d  child=%d  无 target=%d'
                 '（其中 A2=%d ★D70 盯的就是这个数★）'
                 % (digest, len(tmap), len(rows), n_no, n_a2_no))
    for r in rows:
        lines.append('\t'.join(r))
    return '\n'.join(lines) + '\n'


def audit(cls_rows, closure_rows):
    """把 classification.tsv 散文里的「X 不是 FM target」和权威结论对账。

    返回 [(target, child, 说明)] —— 非空即 FAIL。
    """
    truth = dict((r[0], r[2] == 'YES') for r in closure_rows)
    bad = []
    for tgt, _cell, kids, blocker, _klass in cls_rows:
        if not blocker:
            continue
        named = set()
        for m in _CLAIM_NAMED.finditer(blocker):
            for n in m.group(1).split('/'):
                if n:
                    named.add(n)
        claimed = set(n for n in named if n in truth)
        if _CLAIM_ALL.search(blocker):
            claimed |= set(kids)
        for child in sorted(claimed):
            if truth.get(child):
                bad.append((tgt, child,
                            'blocker 断言「%s 不是 FM target」，但权威求值说它是 '
                            '(ut=%s)' % (child, ','.join(
                                sorted(r[3] for r in closure_rows
                                       if r[0] == child)) or '?')))
    return bad


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or HERE.parent))
    ap.add_argument('--commit', default='HEAD')
    ap.add_argument('--tsv', default=None, help='输出文件（默认 %s）' % OUT_TSV)
    ap.add_argument('--audit', action='store_true',
                    help='只把 classification.tsv 的散文断言和权威结论对账，不写文件')
    ap.add_argument('--check', action='store_true',
                    help='不写文件，只校验仓库里的 TSV 与重新生成的结果逐字节一致')
    a = ap.parse_args(argv)
    repo = pathlib.Path(a.repo)
    commit = _rev(repo, a.commit)

    try:
        closure, cls_rows, tmap = build(repo, commit)
    except (FTU.GitError, FTU.MakeUnavailable, FTU.EngineDisagree,
            PS.PolicyError) as e:
        sys.stderr.write('INPUT ERROR (fail-closed): %s\n' % e)
        return 2

    n_no = sum(1 for r in closure if r[5] == V_NO_TARGET)
    n_a2_no = sum(1 for r in closure if r[5] == V_NO_TARGET and 'A2' in r[1])
    n_un = sum(1 for r in closure if r[5] == V_UNVERIFIED)
    print('# repo=%s commit=%s' % (repo, commit))
    print('# FM target 全集=%d（make 权威）；A 类边界 child=%d'
          % (len(tmap), len(closure)))
    print('无 FM target 的 child = %d（其中 A1 厂商宏 %d 个本就不需要自己的 target）'
          % (n_no, n_no - n_a2_no))
    print('★A2（green_child 候选）且无 FM target = %d★ —— D70 盯的就是这个数'
          % n_a2_no)
    print('有 target 但无证书 = %d（UNVERIFIED —— 可经 clean official rerun 出证书变绿）'
          % n_un)
    for r in closure:
        if r[5] == V_NO_TARGET and 'A2' in r[1]:
            print('    A2/NO_FM_TARGET  %-42s 被 %s 引用' % (r[0], r[6]))

    if a.audit:
        bad = audit(cls_rows, closure)
        if bad:
            print('\n★AUDIT FAIL★ classification.tsv 的 blocker 里有 %d 条假断言:' % len(bad))
            for tgt, child, msg in bad:
                print('    %s: %s' % (tgt, msg))
            print('  修法：按 %s 重写 blocker 文字，不要反过来改本表。' % OUT_TSV)
            return 1
        print('\nAUDIT PASS: classification.tsv 里每一句「X 不是 FM target」'
              '都与权威求值一致')
        return 0

    # ★键是输入摘要不是 commit★：把 commit 写进生成物，artifact 一被提交
    # commit 就变了，--check 幂等闸从此永远过不了。
    txt = render(closure, FTU.makefiles_digest(str(repo), commit), tmap)
    path = pathlib.Path(a.tsv) if a.tsv else repo / OUT_TSV
    if a.check:
        cur = path.read_text() if path.exists() else None
        if cur != txt:
            print('★幂等 FAIL★ %s 与重新生成的结果不一致' % path)
            return 1
        print('幂等 PASS: %s 与重新生成的结果逐字节一致' % path)
        return 0
    path.write_text(txt)
    print('wrote %s  sha256=%s' % (path, hashlib.sha256(txt.encode()).hexdigest()))
    return 0


if __name__ == '__main__':
    sys.exit(main())
