#!/usr/bin/env python3
"""coverage_three_axis.py —— codex 0142 §18 的三轴覆盖报告。

分母 = G1 设计 universe（`docs/g1_configured_universe.tsv` 的 in_universe=yes；
XSTop elaborated 集落地后换成它，见 --universe）。**1884 只是定义全集候选，
不是"要跑 1884 份独立 receipt"的目标分母**。

三轴各自回答一个不同的问题，不可互相替代：

1. REWRITE_COVERAGE —— 「这个模块有没有可读实现，且过了 rewritten_floor」
   REWRITTEN       rtl/ 下有同名 module，且过了驱动下限（rewritten_floor）
   PARTIAL_DRIVE / SKELETON / ...  rtl/ 有定义但没过下限（照 rewritten_floor 原样落档）
   GOLDEN_REUSE    rtl/ 里**没有**定义，而 impl 侧直接读 golden 逻辑
                   （UT 的 RTL_GOLDEN_DEPS / receipt impl_closure 里 kind=golden）
                   —— 按 codex 裁定**不算重写完成**，单列
   ★优先级（codex 0238 裁定 1，2026-10-18 改）★：rtl/ 有定义的**先过 floor**，
   别的 UT / 证明 impl 侧还读着 golden 不能把一份已完成的实现盖成 GOLDEN_REUSE。
   起因：XSCore 的 UT 把 golden 整棵子树当仿真依赖读进来，旧逻辑
   `GOLDEN_REUSE if m in reuse else floor` 一下子把 1600 个模块记成 GOLDEN_REUSE，
   其中 1561 个 rtl/ 里有定义 —— 轴一不再回答「有没有可读实现」。
   ★但"谁还在用 golden"这件事不能丢★：另起一列 golden_used_by，列出 impl 侧
   仍读该模块 golden 文件的 UT（ut:<目录>）与证明（fm:<top>，每个 top 取最新一份
   已跟踪、通过的 receipt）。「rtl 有定义」**不是**它被实际用上的证据；这一列非空
   的 run 都不是纯重写 run，不许那样宣称。
   VENDOR_BOUNDARY 已审定的厂商硬宏边界（verif/vendor_boundary.tsv）
   MISSING         还没有可读实现

2. FORMAL_COVERAGE —— 「这个定义有没有被真的证明覆盖」
   ★ledger-cv（2026-10-19，用户批准）：只认对当前 HEAD current-valid 的证明★
   判据 = scripts/proof_currency.py（证书走 proof_certificate.validate_certificate_current；
   只有 receipt 的根把已跟踪 evidence 经 make_proof_certificate.build_certificate 派生后走同一函数）。
   PROVEN_DIRECT   自己是一份 current-valid 证明的 top
   PROVEN_IN_CONE  (a) 自己是证明根但不 current-valid，被一个 current-valid 父 WB1–WB6 白盒覆盖
                       —— proof_status 列写 superseded_by=<父>；
                   (b) 不是证明根，出现在某份 **current-valid** 证明的 golden 闭包里且未被该证明列为黑盒
                   两种都只是候选口径，不进行数台账（见下）
   证明根但既不 current-valid、也无白盒父 → 不给 PROVEN_IN_CONE 候选，按黑盒与否落 BLACKBOXED / UNPROVEN，
                   proof_status 列写 not_current:<原因>
   BLACKBOXED      只以黑盒身份出现在别人的（current-valid）证明里（未受验）
   VENDOR_BOUNDARY 同上，单列
   UNPROVEN        没有任何 current-valid 证明触及
   注意：**"文件出现在 source closure" 不等于覆盖**——可能未被例化或被黑盒，
   故这里用 receipt 的 golden_closure 与 allow 黑盒集做差。
   ★codex 0238 裁定 2★：这个差（closure 文件名 − **当前** allow）只够当**候选**——
   文件被读 ≠ 被例化，当前 allow ≠ 那次 run 的 allow。行数台账里的
   incore_golden_lines_proven_incl_cone 不读本档，只认 verif/proven_in_cone_verified.tsv
   逐条核验过的行（scripts/proven_in_cone.py）。

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

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from rewritten_floor import classify_rtl, counts_as_written

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


def _is_golden_path(tok):
    """依赖清单里的一个文件是不是 golden 文件（按目录名 golden-rtl 认，不按模块名猜）。

    旧 golden_reuse_set 只取 basename，于是 `$(XSSV_HOME)/rtl/common/ClockGate.sv`、
    `$(RTL_DIR)/memblock/*.sv` 这类**本地件**也被当成 golden 复用记了账。"""
    return '/golden-rtl/' in tok.replace('\\', '/')


def ut_golden_users(ut_root=None, repo=None):
    """{模块名: {'ut:<目录>'}} —— 各 UT 仿真时 impl 侧直接读的 golden 文件。

    ★用 make 展开，不用正则★：旧版对 Makefile 文本做正则，`$(addprefix $(GOLDEN_RTL)/,
    $(SRAM_DEPS))` 这类变量间接（实测 35 个 UT）全部展开不了、静默漏记；同一个坑
    fm_target_universe 早就踩过（D70）。展开失败一律 fail-closed 抛出。"""
    import subprocess
    repo = pathlib.Path(repo or REPO)
    ut_root = pathlib.Path(ut_root or (repo / 'verif' / 'ut'))
    out = {}
    for mk in sorted(ut_root.glob('*/Makefile')):
        if 'RTL_GOLDEN_DEPS' not in mk.read_text(errors='replace'):
            continue
        r = subprocess.run(
            ['make', '-s', '--no-print-directory', '-C', str(mk.parent),
             '--eval', '__xs_golden_deps__: ; @echo $(RTL_GOLDEN_DEPS)',
             '__xs_golden_deps__', 'XSSV_HOME=%s' % repo],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        if r.returncode != 0:
            raise SystemExit('coverage_three_axis: 展开 %s 的 RTL_GOLDEN_DEPS 失败（rc=%d）：%s'
                             % (mk, r.returncode, r.stderr.strip()[:300]))
        for tok in r.stdout.split():
            base = tok.rsplit('/', 1)[-1]
            if base.endswith('.sv') and _is_golden_path(tok):
                out.setdefault(base[:-3], set()).add('ut:' + mk.parent.name)
    return out


_RUN_TS = re.compile(r'-(\d{8}T\d{6}Z)-')


def receipt_golden_users(records):
    """{模块名: {'fm:<top>'}} —— 证明 impl 侧直接读的 golden 文件。

    records = [(receipt 相对路径, receipt dict)]。只收通过、非 provisional、
    非 dirty 的；同一 top 只取**最新一份**（run_id 时间戳，平手按路径），
    因为这一列回答的是「现在还有谁在用 golden」，旧 run 用过不代表现行证明还在用。"""
    latest = {}
    for rel, r in records:
        if r.get('verdict') not in PASS:
            continue
        if r.get('provisional') or r.get('impl_worktree_dirty'):
            continue
        m = _RUN_TS.search(r.get('run_id') or '')
        key = (m.group(1) if m else '', rel)
        top = r.get('top')
        if top and (top not in latest or key > latest[top][0]):
            latest[top] = (key, r)
    out = {}
    for top, (_, r) in latest.items():
        for e in r.get('impl_closure') or []:
            p = e.get('path', '')
            if e.get('kind') == 'golden' and p.endswith('.sv'):
                out.setdefault(pathlib.Path(p).name[:-3], set()).add('fm:' + top)
    return out


def tracked_receipts(repo=None):
    """已跟踪的 receipt —— 用法列只认版本库里有的，clean clone 才能复现同一张表。"""
    import subprocess
    repo = pathlib.Path(repo or REPO)
    rels = subprocess.check_output(
        ['git', '-C', str(repo), 'ls-files', 'evidence/*/receipt.json'],
        universal_newlines=True).split()
    out = []
    for rel in sorted(rels):
        try:
            out.append((rel, json.loads((repo / rel).read_text())))
        except (OSError, ValueError):
            continue
    return out


def golden_users(ut=None, rec=None):
    """合并两路用法：{模块名: 排好序的用户列表}。"""
    merged = {}
    for src in (ut_golden_users() if ut is None else ut,
                receipt_golden_users(tracked_receipts()) if rec is None else rec):
        for m, us in src.items():
            merged.setdefault(m, set()).update(us)
    return {m: sorted(us) for m, us in merged.items()}


def axis1(m, vend, rtl, floor, users):
    """轴一判档（codex 0238 裁定 1）：vendor > rtl 有定义走 floor > impl 读 golden > MISSING。"""
    if m in vend:
        return 'VENDOR_BOUNDARY'
    if m in rtl:
        # ★轴一的下限（2026-09-21 加）★：光有 `module <名字>` 不算重写。
        #   rewritten_floor 按**驱动闭包**判——输出得真被驱动，
        #   而且驱动链要落到真逻辑上，不能停在一个空核的端口上。
        #   加这道下限之前，StoreQueue（壳接空核，163/399）和
        #   NewDispatch（5974/6699）都在这张表里写着 REWRITTEN。
        # ★2026-10-18：floor 优先于 golden 用法★（见文件头）——别处还读 golden
        #   只进 golden_used_by 列，不改本列。
        return floor.get(m, ('SKELETON',))[0]
    if m in users:
        return 'GOLDEN_REUSE'
    return 'MISSING'


def proofs(cur=None):
    """current-valid 证明：[(top, golden_closure 模块名集合, 黑盒 design 集合)] + Currency。
    （旧版读磁盘上**所有**通过的 receipt，含过期的与未跟踪的；ledger-cv 起只认 current-valid。）"""
    import proof_currency as PCUR
    cur = cur or PCUR.evaluate()
    out = []
    for top in sorted(cur.cv):
        d = cur.cv[top]
        cone = {pathlib.Path(e['path']).name[:-3]
                for e in d['input_closure']['golden'] if e['path'].endswith('.sv')}
        bb = set()
        ap = REPO / 'verif' / 'allow' / f"{top}.json"
        if ap.exists():
            bb = {o['design'] for o in json.loads(ap.read_text()).get('objects', [])}
        out.append((top, cone, bb))
    return out, cur


def axis2(m, vend, cur, in_cone, blackboxed):
    """轴二判档 → (formal_coverage, proof_status)。cur = proof_currency.Currency。"""
    tier, det = cur.tier(m)
    st = {'PROVEN_DIRECT': 'current_valid:%s' % cur.via.get(m),
          'PROVEN_IN_CONE': 'superseded_by=%s' % det,
          'NOT_CURRENT': 'not_current:%s' % det}.get(tier, '-')
    if m in vend:
        return 'VENDOR_BOUNDARY', st
    if tier in ('PROVEN_DIRECT', 'PROVEN_IN_CONE'):
        return tier, st
    if tier == 'NOT_CURRENT':
        # 证明根但不 current-valid、无白盒父：不给 closure 候选（用户口径 3：不记 proven）
        return ('BLACKBOXED' if m in blackboxed else 'UNPROVEN'), st
    if m in in_cone:
        return 'PROVEN_IN_CONE', st
    if m in blackboxed:
        return 'BLACKBOXED', st
    return 'UNPROVEN', st


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--universe',
                    default=str(REPO / 'docs' / 'g1_configured_universe.tsv'))
    a = ap.parse_args()

    uni = load_universe(a.universe)
    vend = vendor_set()
    rtl = rtl_modules()
    users = golden_users()
    floor = classify_rtl()
    recs, cur = proofs()

    proven_direct = {t for t, _, _ in recs}
    in_cone, blackboxed = set(), set()
    for t, cone, bb in recs:
        in_cone |= (cone - bb)
        blackboxed |= bb

    from gen_xstile_closure import load as load_tile_closure
    tile = load_tile_closure()

    rows = []
    from collections import Counter
    c1, c2, c1_core, c2x = Counter(), Counter(), Counter(), Counter()
    for m in uni:
        a1 = axis1(m, vend, rtl, floor, users)
        a2, pst = axis2(m, vend, cur, in_cone, blackboxed)
        c1[a1] += 1
        c2[a2] += 1
        if m in tile:
            c1_core[a1] += 1
        c2x[pst.split(':')[0].split('=')[0]] += 1
        rows.append((m, a1, a2, str(rtl.get(m, '-')),
                     ','.join(users.get(m, [])) or '-', pst))

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
        f.write('# golden_used_by = impl 侧仍直接读该模块 golden 文件的 UT（ut:）/ 证明（fm:，每 top 最新'
                '一份已跟踪通过 receipt）；非空 ≠ 没重写，但这些 run 都不是纯重写 run\n')
        f.write('# proof_status = 证明根对当前 HEAD 的状态（scripts/proof_currency.py）：current_valid:<certificate|receipt:…> /'
                ' superseded_by=<白盒父>（不 current-valid，WB1–WB6 成立；候选口径，不进行数台账）/'
                ' not_current:<原因>（不 current-valid 且无白盒父：不记 proven）；非证明根为 -\n')
        f.write('# module\trewrite_coverage\tformal_coverage\timpl_file\tgolden_used_by\tproof_status\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')

    n = len(uni)
    print(f'分母（G1 设计 universe 候选）= {n}')
    print('轴1 REWRITE_COVERAGE：', dict(c1.most_common()))
    _wr = sum(v for k, v in c1.items() if counts_as_written(k))
    print(f'      已重写占比 {100*_wr/n:.1f}%'
          f'（GOLDEN_REUSE {c1["GOLDEN_REUSE"]} 不计入，按裁定单列；'
          f'未过驱动下限：PARTIAL_DRIVE {c1["PARTIAL_DRIVE"]} / '
          f'SKELETON {c1["SKELETON"]}，不计入）')
    print('      其中核内（XSTile 闭包 %d 个）：' % sum(c1_core.values()), dict(c1_core.most_common()))
    _gu = sum(1 for r in rows if r[4] != '-')
    _gu_rtl = sum(1 for r in rows if r[4] != '-' and r[3] != '-')
    print(f'      golden_used_by 非空 {_gu} 个（其中 rtl/ 有定义 {_gu_rtl} 个：有实现但仍有 run 读 golden）')
    print('轴2 FORMAL_COVERAGE：', dict(c2.most_common()))
    cov = c2['PROVEN_DIRECT'] + c2['PROVEN_IN_CONE']
    print(f'      被通过证明真实覆盖 {cov}/{n} = {100*cov/n:.1f}%'
          f'（BLACKBOXED {c2["BLACKBOXED"]} 未受验，单列）')
    print(f'      proof_status：{dict(c2x.most_common())}'
          f'（PROVEN_IN_CONE 里 superseded_by {c2x["superseded_by"]} 个是不 current-valid 的旧根，只是候选）')
    print(f'轴3 PROOF_ROOT_STATUS：current-valid 证明根 {len(proven_direct)} 个，'
          f'其组合覆盖 {cov} 个定义；非 provisional、canonical 同源。')
    print(f'台账：{out.relative_to(REPO)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
