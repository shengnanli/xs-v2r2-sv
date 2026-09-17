#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— indexedLSUopTable 家族 UT 的判别力负测（`make mutants`）。

本家族的 UT 是 **16 种输入全穷举**，理论上任何真值差异都必被抓到。这个脚本的
作用不是「怀疑穷举」，而是钉住两件容易悄悄失效的事：
  (1) tb 真的在比对（而不是比了个恒等式）；
  (2) 七个变体各自接的是**自己**的 UOP_IDX（接错参数是薄 wrapper 最典型的错，
      端口 lint 看不见）。

变异全部打在参数化核与薄 wrapper 上，跑 16 拍就够（穷举一圈）。

用法: python3 mutants.py      （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTL = ['xs_indexedLSUopTable_core.sv'] + [f'indexedLSUopTable_{i}.sv' for i in range(1, 8)]
NCYCLES = '160'

MUTANTS = [
    ('M1 lmul<emul 与 lmul>=emul 两支的 vs2/vd 偏移写反', 'xs_indexedLSUopTable_core.sv',
     "      localparam int OFF_VS2 = (UOP_IDX >= NUM_UOP) ? 0\n"
     "                             : (LMUL < EMUL) ? UOP_IDX : (UOP_IDX / OFFSET);",
     "      localparam int OFF_VS2 = (UOP_IDX >= NUM_UOP) ? 0\n"
     "                             : (LMUL < EMUL) ? (UOP_IDX / OFFSET) : UOP_IDX;"),
    ('M2 超出 uop 数时不归 0（Chisel 的 for 走完不命中要返回 (0,0)）',
     'xs_indexedLSUopTable_core.sv',
     "      localparam int OFF_VD  = (UOP_IDX >= NUM_UOP) ? 0\n"
     "                             : (LMUL < EMUL) ? (UOP_IDX / OFFSET) : UOP_IDX;",
     "      localparam int OFF_VD  = (LMUL < EMUL) ? (UOP_IDX / OFFSET) : UOP_IDX;"),
    ('M3 共享倍数 OFFSET 取成两侧之差的相反方向', 'xs_indexedLSUopTable_core.sv',
     "      localparam int OFFSET  = (LMUL < EMUL) ? (1 << (EMUL - LMUL))\n"
     "                                             : (1 << (LMUL - EMUL));",
     "      localparam int OFFSET  = (LMUL < EMUL) ? (1 << (EMUL - LMUL))\n"
     "                                             : 1;"),
    ('M4 src 的 EMUL/LMUL 两个域取反（src[3:2] 是 EMUL）', 'xs_indexedLSUopTable_core.sv',
     "      localparam int EMUL = s >> 2;              // src[3:2]\n"
     "      localparam int LMUL = s & 2'b11;           // src[1:0]",
     "      localparam int EMUL = s & 2'b11;\n"
     "      localparam int LMUL = s >> 2;"),
    ('M5 薄 wrapper 把 _5 接成 UOP_IDX=6（接错参数，端口 lint 看不见）',
     'indexedLSUopTable_5.sv',
     "  xs_indexedLSUopTable_core #(.UOP_IDX(5)) u_core (",
     "  xs_indexedLSUopTable_core #(.UOP_IDX(6)) u_core ("),
    ('M6 薄 wrapper 把 outOffsetVs2 / outOffsetVd 接反', 'indexedLSUopTable_3.sv',
     "    .out_offset_vs2 (outOffsetVs2),\n    .out_offset_vd  (outOffsetVd)",
     "    .out_offset_vs2 (outOffsetVd),\n    .out_offset_vd  (outOffsetVs2)"),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'indexedLSUopTable').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'indexedLSUopTable' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'indexedLSUopTable'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    txt = log.read_text()
    m = re.search(r'TEST FAILED errors=(\d+) \(checks=(\d+)\)', txt)
    if m:
        return (int(m.group(2)), int(m.group(1)))
    m = re.search(r'TEST PASSED \(checks=(\d+)\)', txt)
    return (int(m.group(1)), 0) if m else None


def main():
    prepare()
    print('=== 基线（未变异，%s 拍 = 穷举 10 圈）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)
    missed = []
    for name, fname, old, new in MUTANTS:
        restore()
        tgt = BUILD / 'rtl' / 'backend' / fname
        t = tgt.read_text()
        if old not in t:
            print('!! %s：锚点没找到，变异未生效' % name)
            missed.append(name)
            continue
        tgt.write_text(t.replace(old, new, 1))
        res = run_ut()
        if res is None:
            print('!! %s：编译/运行失败' % name)
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-58s checks=%-8d errors=%-8d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)
    restore()
    if missed:
        print('=== MUTANTS FAILED ===')
        for m in missed:
            print('   ', m)
        return 1
    print('=== MUTANTS PASSED：%d/%d 全部被抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
