#!/usr/bin/env python3
"""生成 L2PipelineLeaves4 的双例化 UT testbench（tb.sv）。

4 对 golden <M> vs 重写 <M>_xs（Pipeline_2 / _3 / _10 / _11，scripts/dual_tb_lib.py），每拍逐位比较全部输出。
两侧各自带自己的 child：golden 侧是 golden Queue1_*，重写侧是派生的 Queue1_*_xs（rtl/frontend 已签核件）。
深度 1 队列的存储寄存器不复位（golden `always @(posedge clock) if (do_enq)`）：+random 档两侧初值不同，
所以等第一次入队之后再比 —— arm = 一次 enq（Pipeline_2/_3 要求 in.valid & in.ready；_10/_11 无 ready
端口，in.valid 即入队），且必须在复位撤销之后：复位期间 valid 位被异步复位压住，第一级虽写了
存储、却不会把数据推进第二级（seed 42 × random 档实测：只认"复位中入队"时 Pipeline_10 第二级
存储仍是两侧各自的随机初值，假失配 2 拍）。Pipeline_10 两级串联、第二级晚一拍写入，再加 arm_delay=1。
激励：in.valid 按 mode 分稀疏/稠密/全随机；out.ready（_2/_3）3/4 为 1，让"满且下游不收"的反压也出现。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

VALID_STIM = """
case (@mode % 3)
  0: @io_in_valid = ($urandom_range(0, 3) == 0);
  1: @io_in_valid = ($urandom_range(0, 3) != 0);
  default: ;
endcase
"""
READY_STIM = VALID_STIM + "@io_out_ready = ($urandom_range(0, 3) != 0);\n"

DECOUPLED_COV = [
    ("enq", "@io_in_valid && @io_in_ready"),
    ("deq", "@io_out_valid && @io_out_ready"),
    ("backpressure", "@io_out_valid && !@io_out_ready"),
    ("enq_deq_same", "@io_in_valid && @io_in_ready && @io_out_valid && @io_out_ready"),
]
PIPE_COV = [
    ("enq", "@io_in_valid"),
    ("out", "@io_out_valid"),
]

PAIRS = [
    Pair("Pipeline_2", "p2_", clocked=True, stim=READY_STIM, cov=DECOUPLED_COV,
         arm=["@io_in_valid && @io_in_ready && !@reset"]),
    Pair("Pipeline_3", "p3_", clocked=True, stim=READY_STIM, cov=DECOUPLED_COV,
         arm=["@io_in_valid && @io_in_ready && !@reset"]),
    Pair("Pipeline_10", "p10_", clocked=True, stim=VALID_STIM, cov=PIPE_COV,
         arm=["@io_in_valid && !@reset"], arm_delay=1),
    Pair("Pipeline_11", "p11_", clocked=True, stim=VALID_STIM, cov=PIPE_COV,
         arm=["@io_in_valid && !@reset"]),
]

HEADER = """
tb —— L2PipelineLeaves4：TL2CHICoupledL2 的 4 个 utility.Pipeline 单态化（Pipeline_2/_3/_10/_11）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
