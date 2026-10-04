#!/usr/bin/env python3
"""生成 ChiRxPipelines 的双例化 UT testbench（tb.sv）。

2 对 golden <M> vs 重写 <M>_xs（Pipeline_12 / _13，scripts/dual_tb_lib.py），每拍逐位比较全部输出。
两侧各自带自己的 child：golden 侧 golden Queue1_CHIDAT/RSP，重写侧派生的 Queue1_CHI*_xs（已签核件）。
深度 1 队列的存储寄存器不复位：+random 档两侧初值不同，所以等复位撤销后的第一次入队之后再比
（同 verif/ut/L2PipelineLeaves4 的 arm 规则）。
激励：in.valid 按 mode 分稀疏/稠密/全随机；out.ready 3/4 为 1，让"满且下游不收"的反压与
pipe 直通（满且下游正在收时同拍入队）都出现。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
case (@mode % 3)
  0: @io_in_valid = ($urandom_range(0, 3) == 0);
  1: @io_in_valid = ($urandom_range(0, 3) != 0);
  default: ;
endcase
@io_out_ready = ($urandom_range(0, 3) != 0);
"""

COV = [
    ("enq", "@io_in_valid && @io_in_ready"),
    ("deq", "@io_out_valid && @io_out_ready"),
    ("backpressure", "@io_out_valid && !@io_out_ready"),
    ("enq_deq_same", "@io_in_valid && @io_in_ready && @io_out_valid && @io_out_ready"),
    ("full_refused", "@io_in_valid && !@io_in_ready"),
]

PAIRS = [
    Pair("Pipeline_12", "p12_", clocked=True, stim=STIM, cov=COV,
         arm=["@io_in_valid && @io_in_ready && !@reset"]),
    Pair("Pipeline_13", "p13_", clocked=True, stim=STIM, cov=COV,
         arm=["@io_in_valid && @io_in_ready && !@reset"]),
]

HEADER = """
tb —— ChiRxPipelines：TL2CHICoupledL2 的 rxdatPipe / rxrspPipe（Pipeline_12 / Pipeline_13）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
