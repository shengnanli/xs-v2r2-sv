#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden L2TLBWrapper vs 重写 L2TLBWrapper_xs）。用法：python3 gen.py [--check]

L2TLBWrapper 与 L2TLB 端口表逐名逐宽相同（gen_l2tlbwrapper.py 断言过），所以激励直接复用
verif/ut/L2TLB/tb.sv（它带 TileLink 在途请求跟踪的 D 通道应答模型、CSR/PMA 定向配置、四道覆盖闸；
纯随机激励会让 L2TLB 的访存通道一次都不握手，本目录第一版就是这样：auto_out_a_valid 从未翻转）。
机械改动（每处必须恰好命中一次，否则生成失败）：
  * golden 实例 `L2TLB u_g` -> `L2TLBWrapper u_g`，重写实例 `L2TLB_xs u_i` -> `L2TLBWrapper_xs u_i`；
    两侧外壳里都是同一个 golden L2TLB（实例名 ptw），比的只是外壳 glue（端口直通 + perf 两拍）；
  * 删掉两个只对 L2TLB 重写核有意义的诊断探针块（xprobe / initreg_probe，引用 u_i.u_core.*）；
  * 加一道外壳自己的覆盖闸：19 个 perf 出口里至少有一个出现过非零值（否则两拍寄存器只在比 0 对 0）。
两个 L2TLB 实例内部有大量不复位寄存器 —— 照 L2TLB UT 的先例只跑 +vcs+initreg+0 / +1 两个常量档。
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'L2TLB', 'tb.sv')
DST = os.path.join(HERE, 'tb.sv')


def sub_once(t, old, new):
    n = t.count(old)
    if n != 1:
        raise SystemExit('gen.py: %r 命中 %d 次（应为 1）' % (old, n))
    return t.replace(old, new)


def build():
    t = open(SRC).read()
    t = sub_once(t, '  L2TLB u_g (', '  L2TLBWrapper u_g (')
    t = sub_once(t, '  L2TLB_xs u_i (', '  L2TLBWrapper_xs u_i (')
    # 两个诊断探针块：按首尾锚点整段删除
    for head, tail in (('    if ($test$plusargs("xprobe")) begin\n', '\n    end\n'),
                       ('    if ($test$plusargs("initreg_probe"))\n', 'hptw_resp_entry_ppn);\n')):
        if t.count(head) != 1:
            raise SystemExit('gen.py: 探针块起点 %r 命中 %d 次' % (head, t.count(head)))
        a = t.index(head)
        b = t.index(tail, a) + len(tail)
        t = t[:a] + t[b:]
    if 'u_core' in t:
        raise SystemExit('gen.py: 删完探针后仍有 u_core 引用')
    perf = ' || '.join('(|g_io_perf_%d_value)' % n for n in range(19))
    t = sub_once(t, '      do_check(t);\n', '      do_check(t);\n      if (%s) n_perf_nz++;\n' % perf)
    t = sub_once(t, '  initial begin\n', '  int n_perf_nz = 0;\n  initial begin\n') if t.count('  initial begin\n') == 1 else \
        t.replace('module tb;\n', 'module tb;\n  int n_perf_nz = 0;\n', 1)
    t = sub_once(t, '    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");',
                 '    $display("perf_nonzero_cycles=%0d", n_perf_nz);\n'
                 '    if (n_perf_nz == 0) begin $display("TEST FAILED: perf 出口从未非零"); $finish; end\n'
                 '    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");')
    hdr = '// 由 verif/ut/L2TLBWrapper/gen.py 从 verif/ut/L2TLB/tb.sv 机械派生（勿手改）\n'
    return hdr + t


txt = build()
cur = open(DST).read() if os.path.exists(DST) else None
if '--check' in sys.argv:
    print(('[gencheck] %s OK' if cur == txt else '[gencheck] %s DRIFT') % DST)
    sys.exit(0 if cur == txt else 1)
if cur != txt:
    open(DST, 'w').write(txt)
    print('wrote %s' % DST)
