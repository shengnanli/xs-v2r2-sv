#!/usr/bin/env python3
"""生成 LCredit2Decoupled_2 的双例化 UT testbench（tb.sv）：golden vs 重写 LCredit2Decoupled_2_xs
（scripts/dual_tb_lib.py），每拍逐位比较全部输出。
激励偏置：link state 3/4 为 RUN（2'h2，否则从不发信用）；flit 的 opcode 字段 [52:49] 1/4 取 0
（DATLCrdReturn，只还信用不出数据）；flitv 按 mode 分稀疏/稠密/全随机；out.ready 3/4 为 1。
计数器两个、lcrdv 一个，全异步复位；按 reset_period 随机再复位。
覆盖：发信用、收 flit、LCrdReturn 被吞、同拍发+收、信用池耗尽（inflight=15 即 pool=0）、reclaim。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
if ($urandom_range(0, 3) != 0) @io_state_state = 2'h2;
if ($urandom_range(0, 3) == 0) @io_in_flit[52:49] = 4'h0;
case (@mode % 3)
  0: @io_in_flitv = ($urandom_range(0, 3) == 0);
  1: @io_in_flitv = ($urandom_range(0, 3) != 0);
  default: ;
endcase
@io_out_ready = ($urandom_range(0, 3) != 0);
"""
COV = [
    ("lcrdv", "@io_in_lcrdv"),
    ("data_out", "@io_out_valid && @io_out_ready"),
    ("lcrd_return_dropped", "@io_in_flitv && @io_in_flit[52:49] == 4'h0 && !@io_reclaimLCredit"),
    ("pool_empty", "%su_gold.lcreditPool == 5'h0" % "lc_"),
    ("reclaim", "@io_reclaimLCredit"),
]
PAIRS = [Pair("LCredit2Decoupled_2", "lc_", clocked=True, stim=STIM, cov=COV)]
HEADER = """
tb —— LCredit2Decoupled_2：L2 LinkMonitor 的 RXDAT 链路层接收端（非阻塞、15 信用）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
