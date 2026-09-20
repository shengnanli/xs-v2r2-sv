#!/usr/bin/env python3
"""coverage_three_axis.py —— codex 0142 §18 的三轴覆盖报告。

分母 = G1 设计 universe（`docs/g1_configured_universe.tsv` 的 in_universe=yes；
XSTop elaborated 集落地后换成它，见 --universe）。**1884 只是定义全集候选，
不是"要跑 1884 份独立 receipt"的目标分母**。

三轴各自回答一个不同的问题，不可互相替代：

1. REWRITE_COVERAGE —— 「这个模块有没有可读实现」
   REWRITTEN       rtl/ 下有同名 module，且不是直接引用 golden 文件
   GOLDEN_REUSE    impl 侧直接读 golden 逻辑（RTL_GOLDEN_DEPS 里的行为模型/闭包）
                   —— 按 codex 裁定**不算重写完成**，单列
   VENDOR_BOUNDARY 已审定的厂商硬宏边界（verif/vendor_boundary.tsv）
   MISSING         还没有可读实现

2. FORMAL_COVERAGE —— 「这个定义有没有被真的证明覆盖」
   PROVEN_DIRECT   自己就是某份通过 receipt 的 top
   PROVEN_IN_CONE  出现在某份通过 receipt 的 golden 闭包里（= 该证明里两侧都
                   elaborate 了它，真受验），且未被该证明列为黑盒
   BLACKBOXED      只以黑盒身份出现在别人的证明里（未受验）
   VENDOR_BOUNDARY 同上，单列
   UNPROVEN        没有任何通过 receipt 触及
   注意：**"文件出现在 source closure" 不等于覆盖**——可能未被例化或被黑盒，
   故这里用 receipt 的 golden_closure 与 allow 黑盒集做差。

3. PROOF_ROOT_STATUS —— 「策展的证明根集是否全过，其组合是否盖住全集」
   不要求每个 module 单独跑一次 FM：父级白盒证明与 green_child 组合可覆盖多个定义。
"""
import argparse
import hashlib
import json
import os
import pathlib
import re
import sys

REPO = pathlib.Path(os.environ.get('XSSV_HOME') or
                    pathlib.Path(__file__).resolve().parent.parent)
PASS = {'SUCCEEDED', 'PASS_DEAD_REF'}


def load_universe(path):
    out = []
    for ln in pathlib.Path(path).read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        c = ln.split('\t')
        if len(c) >= 2 and c[1] == 'yes':
            out.append(c[0])
    return out


def vendor_set():
    f = REPO / 'verif' / 'vendor_boundary.tsv'
    return {l.split('\t')[0] for l in f.read_text().splitlines()
            if l.strip() and not l.startswith('#')} if f.exists() else set()


def rtl_modules():
    """rtl/ 下声明的模块 → 定义文件。"""
    idx = {}
    for p in (REPO / 'rtl').rglob('*.sv'):
        for m in re.finditer(r'^module\s+(\w+)', p.read_text(errors='replace'), re.M):
            idx[m.group(1)] = p.relative_to(REPO)
    return idx


def golden_reuse_set():
    """各 UT Makefile 的 RTL_GOLDEN_DEPS：impl 侧直接读的 golden 文件（非重写）。"""
    out = set()
    for mk in (REPO / 'verif' / 'ut').glob('*/Makefile'):
        txt = re.sub(r'\\\n', ' ', mk.read_text())
        m = re.search(r'^RTL_GOLDEN_DEPS\s*=\s*(.*)$', txt, re.M)
        if m:
            for tok in m.group(1).split():
                base = tok.split('/')[-1]
                if base.endswith('.sv'):
                    out.add(base[:-3])
    return out


def receipts():
    """通过的 receipt：[(top, golden_closure 模块名集合, 黑盒 design 集合)]"""
    out = []
    for rp in sorted((REPO / 'evidence').rglob('receipt.json')) \
            if (REPO / 'evidence').exists() else []:
        r = json.loads(rp.read_text())
        if r.get('verdict') not in PASS:
            continue
        if r.get('provisional') or r.get('impl_worktree_dirty'):
            continue
        cone = {pathlib.Path(e['path']).name[:-3]
                for e in r.get('golden_closure', [])
                if e['path'].endswith('.sv')}
        bb = set()
        ap = REPO / 'verif' / 'allow' / f"{r['top']}.json"
        if ap.exists():
            bb = {o['design'] for o in json.loads(ap.read_text()).get('objects', [])}
        out.append((r['top'], cone, bb))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--universe',
                    default=str(REPO / 'docs' / 'g1_configured_universe.tsv'))
    a = ap.parse_args()

    uni = load_universe(a.universe)
    vend = vendor_set()
    rtl = rtl_modules()
    reuse = golden_reuse_set()
    recs = receipts()

    proven_direct = {t for t, _, _ in recs}
    in_cone, blackboxed = set(), set()
    for t, cone, bb in recs:
        in_cone |= (cone - bb)
        blackboxed |= bb

    rows = []
    from collections import Counter
    c1, c2 = Counter(), Counter()
    for m in uni:
        if m in vend:
            a1 = a2 = 'VENDOR_BOUNDARY'
        else:
            if m in rtl:
                a1 = 'GOLDEN_REUSE' if m in reuse else 'REWRITTEN'
            elif m in reuse:
                a1 = 'GOLDEN_REUSE'
            else:
                a1 = 'MISSING'
            if m in proven_direct:
                a2 = 'PROVEN_DIRECT'
            elif m in in_cone:
                a2 = 'PROVEN_IN_CONE'
            elif m in blackboxed:
                a2 = 'BLACKBOXED'
            else:
                a2 = 'UNPROVEN'
        c1[a1] += 1
        c2[a2] += 1
        rows.append((m, a1, a2, str(rtl.get(m, '-'))))

    out = REPO / 'docs' / 'coverage_three_axis.tsv'
    with out.open('w') as f:
        # ★写相对路径★：这里原先写 a.universe 的**绝对**路径，于是同一份表在不同
        #  worktree 里重算出来的字节不同（我在 /home/eda/xs-env/wt-lqr3 重算，
        #  表头就从 .../xs-v2-sv/docs/... 变成 .../wt-lqr3/docs/...），
        #  「幂等闸」于是变成「只有在某台机器的某个目录下才绿」。
        try:
            _uni_disp = os.path.relpath(a.universe, REPO)
        except ValueError:
            _uni_disp = a.universe
        f.write(f'# 三轴覆盖（分母 = {_uni_disp} 的 in_universe=yes，共 {len(uni)}）\n')
        f.write('# module\trewrite_coverage\tformal_coverage\timpl_file\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')

    n = len(uni)
    print(f'分母（G1 设计 universe 候选）= {n}')
    print('轴1 REWRITE_COVERAGE：', dict(c1.most_common()))
    print(f'      已重写占比 {100*c1["REWRITTEN"]/n:.1f}%'
          f'（GOLDEN_REUSE {c1["GOLDEN_REUSE"]} 不计入，按裁定单列）')
    print('轴2 FORMAL_COVERAGE：', dict(c2.most_common()))
    cov = c2['PROVEN_DIRECT'] + c2['PROVEN_IN_CONE']
    print(f'      被通过证明真实覆盖 {cov}/{n} = {100*cov/n:.1f}%'
          f'（BLACKBOXED {c2["BLACKBOXED"]} 未受验，单列）')
    print(f'轴3 PROOF_ROOT_STATUS：通过 receipt 的证明根 {len(proven_direct)} 个，'
          f'其组合覆盖 {cov} 个定义；非 provisional、canonical 同源。')
    print(f'台账：{out.relative_to(REPO)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
