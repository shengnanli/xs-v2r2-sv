#!/usr/bin/env python3
"""生成 Pipeline_1 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden vs Pipeline_1_xs，全部输出逐拍比较。随机 enq/deq（各约一半），覆盖（pipe=1：满且本拍出队时可同拍入队）
入队 / 出队 / 满时背压；ram 不复位，第一笔入队之后才比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

COV = [
    ("enq", "@io_in_valid && @io_in_ready"),
    ("deq", "@io_out_valid && @io_out_ready"),
    ("full_stall", "@io_out_valid && !@io_out_ready && @io_in_valid"),
    ("pipe_through", "@io_out_valid && @io_out_ready && @io_in_valid && @io_in_ready"),
    ("reset_mid", "@reset && cyc > 100"),
]

PAIRS = [Pair("Pipeline_1", "p_", clocked=True, cov=COV,
              reset_period=2000, cov_min=50,
              arm=["@io_in_valid && @io_in_ready"])]

HEADER = """自动生成：verif/ut/Pipeline_1/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
Pipeline_1 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
