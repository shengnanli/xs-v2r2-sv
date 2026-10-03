#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
两个都是纯组合模块：BusPerfMonitor 全随机即可；Arbiter3 的三路 valid 各 1/2，覆盖三种胜者与无人请求。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

A = 'Arbiter3_L2TLBImp_Anon'
arb_cov = [('none', '!@io_out_valid'),
           ('win0', '@io_in_0_valid && @io_in_0_ready'),
           ('win1', '!@io_in_0_valid && @io_in_1_valid && @io_in_1_ready'),
           ('win2', '!@io_in_0_valid && !@io_in_1_valid && @io_in_2_valid && @io_in_2_ready'),
           ('blocked', '@io_out_valid && !@io_out_ready')]
pairs = [Pair('BusPerfMonitor', 'b_'),
         Pair(A, 'a_', cov=arb_cov, cov_min=200)]
txt = render(pairs, header="BusArbLeaves 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
