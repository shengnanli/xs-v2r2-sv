#!/usr/bin/env python3
"""生成 Queue1_RegMapperInput_6 的双例化 UT testbench（tb.sv）。

golden Queue1_RegMapperInput_6 vs 重写 Queue1_RegMapperInput_6_xs（scripts/dual_tb_lib.py）。
随机 enq/deq，覆盖 入队 / 出队 / 满时背压；数据槽不复位，第一笔入队之后才比（arm）。
（CtrlUnit 目录的 tb 里也有同一对，那里是为了父级一起回归；签核走本目录。）

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

COV = [
    ("enq", "@io_enq_valid && @io_enq_ready"),
    ("deq", "@io_deq_valid && @io_deq_ready"),
    ("full_stall", "@io_deq_valid && !@io_deq_ready && @io_enq_valid"),
    # 同拍进出结构上不可能（enq_ready = ~full，deq 只在 full 时），不设此闸
    ("reset_mid", "@reset && cyc > 100"),
]

PAIRS = [
    Pair("Queue1_RegMapperInput_6", "q_", clocked=True, cov=COV,
         reset_period=2000, cov_min=20,
         arm=["@io_enq_valid && @io_enq_ready"]),
]

HEADER = """自动生成：verif/ut/Queue1_RegMapperInput_6/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
Queue1_RegMapperInput_6 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
