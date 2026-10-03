#!/usr/bin/env python3
"""生成 FastArbiterL2c 的双例化 UT testbench（tb.sv）。

3 对 golden <M> vs 重写 <M>_xs（FastArbiter / FastArbiter_1 / FastArbiter_26，scripts/dual_tb_lib.py），
每拍逐位比较全部输出（in_k_ready、out_valid、全部载荷字段、io_chosen）。
激励：每路 valid 按 mode 分"稀疏（1/4）/ 稠密（3/4）/ 全随机"三档，out_ready 3/4 为 1（让握手常发生、
挂起掩码不断更新，轮转分支 rrValid 才走得到）。两张掩码寄存器异步复位，按 reset_period 随机再复位。
覆盖：握手、多路竞争、"轮转候选中签"（golden 内部 rrSelOH & valids 非 0）、各路 ready。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
for (int k = 0; k < 1; k++) begin end
case (@mode % 3)
  0: begin
    @io_in_0_valid = ($urandom_range(0, 3) == 0); @io_in_1_valid = ($urandom_range(0, 3) == 0);
    @io_in_2_valid = ($urandom_range(0, 3) == 0); @io_in_3_valid = ($urandom_range(0, 3) == 0);
  end
  1: begin
    @io_in_0_valid = ($urandom_range(0, 3) != 0); @io_in_1_valid = ($urandom_range(0, 3) != 0);
    @io_in_2_valid = ($urandom_range(0, 3) != 0); @io_in_3_valid = ($urandom_range(0, 3) != 0);
  end
  default: ;
endcase
@io_out_ready = ($urandom_range(0, 3) != 0);
""".replace("for (int k = 0; k < 1; k++) begin end\n", "")


def cov(pfx):
    return [
        ("fire", "@io_out_ready && @io_out_valid"),
        ("contend", "@io_in_0_valid && @io_in_3_valid && @io_out_ready"),
        ("rr_pick", "|(%su_gold.rrSelOH & %su_gold.valids)" % (pfx, pfx)),
        ("grant3", "@io_in_3_ready"),
        ("grant0", "@io_in_0_ready"),
    ]


PAIRS = [
    Pair("FastArbiter", "fa0_", clocked=True, stim=STIM, cov=cov("fa0_")),
    Pair("FastArbiter_1", "fa1_", clocked=True, stim=STIM, cov=cov("fa1_")),
    Pair("FastArbiter_26", "fa26_", clocked=True, stim=STIM, cov=cov("fa26_")),
]

HEADER = """
tb —— FastArbiterL2c：L2 顶层 3 个 FastArbiter 变体（FastArbiter / _1 / _26）的双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
