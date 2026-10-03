#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
两侧都是 golden L2TLB 闭包，比的只是外壳 glue：全随机激励即可（L2TLB 内部怎么走两侧都一样）。
外壳的 38 个 perf 打拍寄存器不复位：0 时刻之后把重写侧 force 成 golden 侧再 release。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

T = 'L2TLBWrapper'
g, i = 'w_u_gold', 'w_u_impl'
F = [f'  force {i}.perf_stage1[{n}] = {g}.io_perf_{n}_value_REG;\n  force {i}.perf_stage2[{n}] = {g}.io_perf_{n}_value_REG_1;'
     for n in range(19)]
R = [f'  release {i}.perf_stage1[{n}];\n  release {i}.perf_stage2[{n}];' for n in range(19)]
decls = "initial begin\n  #1;\n" + "\n".join(F) + "\n  #0;\n" + "\n".join(R) + "\nend\n"
cov = [('perf_nz', '|@io_perf_0_value || |@io_perf_3_value || |@io_perf_10_value'),
       ('ptw_req', '@auto_out_a_valid && @auto_out_a_ready'),
       ('tlb_resp', '@io_tlb_0_resp_valid || @io_tlb_1_resp_valid')]
pairs = [Pair(T, 'w_', clocked=True, cov=cov, decls=decls, reset_period=20000, cov_min=10, exempt=())]
txt = render(pairs, header="L2TLBWrapper 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
