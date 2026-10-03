#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]

L2TLB 的 5 个固定优先级仲裁器（scripts/gen_arbiter_l2tlb_leaves.py 生成的薄文件），全是纯组合：
每拍全部输入随机。每路 valid 各 1/2，覆盖每一路胜出、无人请求、下游不收（out_ready=0）。
Arbiter2_L2TLBImp_Anon_1 没有 out_ready（恒 1），故不计"blocked"。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402


def arb_cov(n, has_out_ready=True):
    cov = [('none', '!@io_out_valid')]
    for k in range(n):
        higher = ''.join('!@io_in_%d_valid && ' % j for j in range(k))
        cov.append(('win%d' % k, higher + '@io_in_%d_valid' % k))
    if has_out_ready:
        cov.append(('blocked', '@io_out_valid && !@io_out_ready'))
    return cov


pairs = [
    Pair('Arbiter1_L2TLBImp_Anon', 'a1_', cov=arb_cov(1), cov_min=200),
    Pair('Arbiter2_L2TLBImp_Anon_1', 'a2_', cov=arb_cov(2, has_out_ready=False), cov_min=200),
    Pair('Arbiter3_bitmapReqBundle', 'a3_', cov=arb_cov(3), cov_min=200),
    Pair('Arbiter4_L2TlbMemReqBundle', 'a4_', cov=arb_cov(4), cov_min=200),
    Pair('Arbiter5_L2TlbWithHptwIdBundle', 'a5_', cov=arb_cov(5), cov_min=200),
]
txt = render(pairs, header="L2TlbArbLeaves 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
