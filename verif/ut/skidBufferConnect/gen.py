#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
out_ready 分相（快相 3/4、慢相 1/4），flush 1/32；dataBuffer 不复位：0 时刻之后把重写侧向量 force 成
golden 侧各字段（按出口字段顺序，含入口没有的那些常零字段）的拼接，只对齐上电初值；state 虽有复位，但 reset 在第一个时钟沿之后才拉起，也一并对齐。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

T = 'skidBufferConnect'
P = golden_ports(T)
outf = [n[len('io_out_bits_'):] for d, w, n in P if n.startswith('io_out_bits_')]
g = 's_u_gold'
i = 's_u_impl.u_core'
decls = ("initial begin\n  #1;\n"
         + "  force %s.dataBuffer = {%s};\n" % (i, ', '.join(g + '.dataBuffer_' + f for f in outf))
         + "  force %s.state = %s.state;\n" % (i, g)
         + "  #0;\n  release %s.dataBuffer;\n  release %s.state;\nend\n" % (i, i))
stim = """
@io_flush     = ($urandom_range(0, 31) == 0);
@io_out_ready = (@mode >= 8) ? ($urandom_range(0, 3) != 0) : ($urandom_range(0, 3) == 0);
""".replace('@mode', 's_mode')
cov = [('capture',   '@io_in_valid && @io_in_ready && !@io_out_ready'),
       ('skid',      '!@io_in_ready'),
       ('drain',     '!@io_in_ready && @io_out_ready'),
       ('flush_skid', '!@io_in_ready && @io_flush && !@io_out_ready'),
       ('flush_cap', '@io_in_valid && @io_in_ready && !@io_out_ready && @io_flush'),
       ('pass',      '@io_in_valid && @io_in_ready && @io_out_ready')]
# 入口没有的字段：出口在直通态恒 0、skid 态给常零寄存器 -> 永远是 0，覆盖闸豁免
inf = {n[len('io_in_bits_'):] for d, w, n in P if n.startswith('io_in_bits_')}
exempt = ['io_out_bits_' + f for f in outf if f not in inf]
pairs = [Pair(T, 's_', clocked=True, stim=stim, cov=cov, decls=decls, exempt=exempt, reset_period=20000, cov_min=200)]
txt = render(pairs, header="skidBufferConnect 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
