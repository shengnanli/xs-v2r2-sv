#!/usr/bin/env python3
"""生成 AsyncResetSyncShiftReg_w1_d3_i0 的双例化 UT testbench（tb.sv）：golden
AsyncResetSynchronizerShiftReg_w1_d3_i0 vs 重写 _xs（scripts/dual_tb_lib.py），每拍逐位比较 io_q。
reset_period 调小（每 ~50 拍一次随机异步复位），让"复位中途清空移位链"常发生；io_d 每拍随机。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

PAIRS = [Pair("AsyncResetSynchronizerShiftReg_w1_d3_i0", "ar_", clocked=True, reset_period=50,
              cov=[("q1", "@io_q"), ("in_reset", "@reset"), ("d_rise", "@io_d && !@io_q")])]
HEADER = """
tb —— AsyncResetSyncShiftReg_w1_d3_i0：1 位 3 级异步复位同步器（装配壳）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
