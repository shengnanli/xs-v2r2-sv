#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_csrctl_leaves5.py —— 5 个 CSR 控制/计数叶 wrapper 的 GENERATED 区生成器。

对象（全部是 NewCSR 的直接 child、0 子模块叶）：
  FcsrModule（fcsr=fflags+frm）、DcsrModule（dcsr）、VcsrModule（vcsr=vxsat+vxrm）、
  McycleModule（mcycle）、MinstretModule（minstret）。

每个 rtl/backend/<Top>.sv = 手写文件头 + 手写 xs_<Top>_core（本脚本不碰） + 一段
`// BEGIN GENERATED(csrctl5)` … `// END GENERATED`，内容为：
  1. golden 同名模块的端口表（从 golden 逐行解析，方向/位宽/顺序逐位对齐）；
  2. xs_<Top>_core u_core 的例化连线（core 语义名 <-> golden 端口名的映射写死在
     本脚本的 MAPS 里）。

双向全覆盖断言（防"名字打错安静地全 0"那一族事故）：
  * golden 解析出的端口集合 == MAPS 映射的 golden 侧集合（两个方向都查）；
  * 目标文件里 xs_<Top>_core 实际声明的端口集合 == MAPS 映射的 core 侧集合，
    且逐端口方向一致（core 是手写的，这条把"core 改了忘改映射"变成显式失败）。

用法: python3 scripts/gen_csrctl_leaves5.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 的幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
OUT_DIR = REPO / 'rtl' / 'backend'
BEGIN = '// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改'
END = '// END GENERATED'

# (core 端口, golden 端口)，按 core 端口表顺序
MAPS = {
    'FcsrModule': [
        ('clock', 'clock'),
        ('reset', 'reset'),
        ('csr_wen', 'w_wen'),
        ('csr_wdata', 'w_wdata'),
        ('cmt_fflags_valid', 'robCommit_fflags_valid'),
        ('cmt_fflags_bits', 'robCommit_fflags_bits'),
        ('alias_fflags_wen', 'wAliasFflags_wen'),
        ('alias_fflags_wdata', 'wAliasFflags_wdata'),
        ('alias_frm_wen', 'wAliasFfm_wen'),
        ('alias_frm_wdata', 'wAliasFfm_wdata'),
        ('rdata', 'rdata'),
        ('fflags', 'fflags'),
        ('frm', 'frm'),
        ('fflags_rdata', 'fflagsRdata'),
        ('frm_rdata', 'frmRdata'),
    ],
    'DcsrModule': [
        ('clock', 'clock'),
        ('reset', 'reset'),
        ('csr_wen', 'w_wen'),
        ('csr_wdata', 'w_wdata'),
        ('trap_valid', 'trapToD_dcsr_valid'),
        ('trap_cause', 'trapToD_dcsr_bits_CAUSE'),
        ('trap_v', 'trapToD_dcsr_bits_V'),
        ('trap_prv', 'trapToD_dcsr_bits_PRV'),
        ('dret_valid', 'retFromD_dcsr_valid'),
        ('dret_v', 'retFromD_dcsr_bits_V'),
        ('dret_prv', 'retFromD_dcsr_bits_PRV'),
        ('nmip', 'nmip'),
        ('rdata', 'rdata'),
        ('f_cetrig', 'regOut_CETRIG'),
        ('f_ebreakvs', 'regOut_EBREAKVS'),
        ('f_ebreakvu', 'regOut_EBREAKVU'),
        ('f_ebreakm', 'regOut_EBREAKM'),
        ('f_ebreaks', 'regOut_EBREAKS'),
        ('f_ebreaku', 'regOut_EBREAKU'),
        ('f_stepie', 'regOut_STEPIE'),
        ('f_stopcount', 'regOut_STOPCOUNT'),
        ('f_stoptime', 'regOut_STOPTIME'),
        ('f_cause', 'regOut_CAUSE'),
        ('f_v', 'regOut_V'),
        ('f_mprven', 'regOut_MPRVEN'),
        ('f_nmip', 'regOut_NMIP'),
        ('f_step', 'regOut_STEP'),
        ('f_prv', 'regOut_PRV'),
    ],
    'VcsrModule': [
        ('clock', 'clock'),
        ('csr_wen', 'w_wen'),
        ('csr_wdata', 'w_wdata'),
        ('cmt_vxsat_valid', 'robCommit_vxsat_valid'),
        ('cmt_vxsat_bits', 'robCommit_vxsat_bits'),
        ('alias_vxsat_wen', 'wAliasVxsat_wen'),
        ('alias_vxsat_wdata', 'wAliasVxsat_wdata'),
        ('alias_vxrm_wen', 'wAliasVxrm_wen'),
        ('alias_vxrm_wdata', 'wAliasVxrm_wdata'),
        ('rdata', 'rdata'),
        ('vxsat', 'vxsat'),
        ('vxrm', 'vxrm'),
    ],
    'McycleModule': [
        ('clock', 'clock'),
        ('reset', 'reset'),
        ('csr_wen', 'w_wen'),
        ('csr_wdata', 'w_wdata'),
        ('inhibit', 'mcountinhibit_CY'),
        ('value', 'rdata'),
        ('value_mirror', 'regOut_ALL'),
    ],
    'MinstretModule': [
        ('clock', 'clock'),
        ('reset', 'reset'),
        ('csr_wen', 'w_wen'),
        ('csr_wdata', 'w_wdata'),
        ('inhibit', 'mcountinhibit_IR'),
        ('retired_num', 'robCommit_instNum_bits'),
        ('value', 'rdata'),
        ('value_mirror', 'regOut_ALL'),
    ],
}


def die(msg):
    sys.exit(f'gen_csrctl_leaves5: {msg}')


def parse_golden_ports(top):
    """从 golden 解析端口表：返回 [(dir, range, name)]，顺序与 golden 一致。"""
    txt = (GOLDEN / f'{top}.sv').read_text()
    m = re.search(r'^module ' + top + r'\(\n(.*?)\n\);\n', txt, re.S | re.M)
    if not m:
        die(f'{top}: golden 里找不到 module 体')
    ports = []
    for ln in m.group(1).split('\n'):
        pm = re.match(r"^\s+(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+),?$", ln)
        if not pm:
            die(f'{top}: 端口行形状不认识: {ln!r}')
        rng = f'[{pm.group(2)}:{pm.group(3)}]' if pm.group(2) is not None else ''
        ports.append((pm.group(1), rng, pm.group(4)))
    if not ports:
        die(f'{top}: golden 端口表为空')
    return ports


def parse_core_ports(top, head):
    """从手写区解析 xs_<Top>_core 的端口表：返回 [(dir, name)]。"""
    m = re.search(r'module\s+xs_' + top + r'_core\s*\((.*?)\n\);', head, re.S)
    if not m:
        die(f'{top}: 手写区里找不到 xs_{top}_core 的端口表')
    body = re.sub(r'//[^\n]*', '', m.group(1))
    ports = []
    for ln in body.split('\n'):
        ln = ln.strip()
        if not ln:
            continue
        pm = re.match(r'^(input|output)\s+logic\s+(?:\[\d+:\d+\]\s+)?(\w+),?$', ln)
        if not pm:
            die(f'{top}: core 端口行形状不认识: {ln!r}')
        ports.append((pm.group(1), pm.group(2)))
    return ports


def gen_block(top, head):
    gports = parse_golden_ports(top)
    mapping = MAPS[top]
    gset = {n for _, _, n in gports}
    gdir = {n: d for d, _, n in gports}
    map_g = [g for _, g in mapping]
    if len(set(map_g)) != len(map_g):
        die(f'{top}: MAPS 的 golden 侧有重复映射')
    if set(map_g) != gset:
        die(f'{top}: MAPS 与 golden 端口集合不一致: '
            f'map-only={sorted(set(map_g) - gset)} golden-only={sorted(gset - set(map_g))}')

    # core 端口交叉核对（手写 core vs 本脚本映射，方向也要一致）
    cports = parse_core_ports(top, head)
    cset = {n for _, n in cports}
    cdir = {n: d for d, n in cports}
    map_c = [c for c, _ in mapping]
    if len(set(map_c)) != len(map_c):
        die(f'{top}: MAPS 的 core 侧有重复映射')
    if set(map_c) != cset:
        die(f'{top}: MAPS 与 xs_{top}_core 端口集合不一致: '
            f'map-only={sorted(set(map_c) - cset)} core-only={sorted(cset - set(map_c))}')
    for c, g in mapping:
        if cdir[c] != gdir[g]:
            die(f'{top}: 端口方向不一致: core.{c}={cdir[c]} golden.{g}={gdir[g]}')

    out = [BEGIN, f'module {top}(']
    w_dir = max(len(d) for d, _, _ in gports)
    w_rng = max(len(r) for _, r, _ in gports)
    for i, (d, r, n) in enumerate(gports):
        sep = ',' if i < len(gports) - 1 else ''
        out.append(f'  {d.ljust(w_dir)} {r.ljust(w_rng)} {n}{sep}')
    out.append(');')
    out.append('')
    out.append(f'  xs_{top}_core u_core (')
    wp = max(len(c) for c, _ in mapping)
    for i, (c, g) in enumerate(mapping):
        sep = ',' if i < len(mapping) - 1 else ''
        out.append(f'    .{c.ljust(wp)} ({g}){sep}')
    out.append('  );')
    out.append('endmodule')
    out.append(END)
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    drift = 0
    for top in MAPS:
        path = OUT_DIR / f'{top}.sv'
        if not path.exists():
            die(f'{path} 不存在：手写文件头与 xs_{top}_core 要先写好（本脚本只替换 GENERATED 区）')
        txt = path.read_text()
        if txt.count(BEGIN) != 1 or txt.count(END) != 1:
            die(f'{path}: GENERATED 标记必须各恰好一个')
        head, rest = txt.split(BEGIN, 1)
        _, tail = rest.split(END + '\n', 1)
        block = gen_block(top, head)
        new = head + block + tail
        if new != txt:
            drift += 1
            if args.check:
                print(f'DRIFT {path.relative_to(REPO)}')
            else:
                path.write_text(new)
                print(f'wrote {path.relative_to(REPO)}')
        else:
            print(f'  {top}: 无漂移（{len(MAPS[top])} 端口）')
    if args.check and drift:
        print(f'gen_csrctl_leaves5 --check: DRIFT ({drift} files)')
        return 1
    if args.check:
        print(f'gen_csrctl_leaves5 --check: OK ({len(MAPS)} files)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
