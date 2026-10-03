#!/usr/bin/env python3
"""生成 MaxPeriodFibonacciLFSR 的双例化 UT testbench（tb.sv）。

golden MaxPeriodFibonacciLFSR vs 重写 MaxPeriodFibonacciLFSR_xs（scripts/dual_tb_lib.py，端口表读 G1 golden）。
被测件只有 clock/reset 两个输入：激励就是复位 —— 上电 8 拍复位，之后每拍 1/5000 概率再打一拍
异步复位（复位值 seed=1 与反馈抽头都要被走到）。逐拍比全部 15 位输出；每个输出位都要见过 0 和 1。
覆盖：复位后第一拍（seed 态）、状态回到 seed（满周期 32767 拍才会自然发生一次，200k 拍内应有若干次）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

SEED_STATE = "({@io_out_14,@io_out_13,@io_out_12,@io_out_11,@io_out_10,@io_out_9,@io_out_8," \
             "@io_out_7,@io_out_6,@io_out_5,@io_out_4,@io_out_3,@io_out_2,@io_out_1,@io_out_0} == 15'd1)"

pair = Pair(
    "MaxPeriodFibonacciLFSR", "l_", clocked=True,
    reset_period=5000,
    cov=[("reset_cycles", "@reset"),
         ("at_seed_state", SEED_STATE + " && !@reset")],
    cov_min=3,
)

txt = render([pair], header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
