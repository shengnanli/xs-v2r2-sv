#!/usr/bin/env python3
"""生成 Arbiter8_MainPipeReq 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

纯组合仲裁器：golden vs Arbiter8_MainPipeReq_xs 全部输出逐拍比较。
激励：8 路 valid 位图按 mode 混合 全 0 / 单热 / 稀疏 / 全随机（每一路都能胜出，也覆盖无人请求时
兜底取第 7 路载荷）；载荷逐位随机；out_ready 一半为 0。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [7:0] a_vmap;
"""

STIM = """
case (cyc % 4)
  0: a_vmap = 8'h00;
  1: a_vmap = 8'h01 << $urandom_range(0, 7);
  2: a_vmap = 8'($urandom) & 8'($urandom) & 8'($urandom);
  default: a_vmap = 8'($urandom);
endcase
{@io_in_7_valid, @io_in_6_valid, @io_in_5_valid, @io_in_4_valid,
 @io_in_3_valid, @io_in_2_valid, @io_in_1_valid, @io_in_0_valid} = a_vmap;
"""

COV = [("none", "!@io_out_valid"), ("stall", "@io_out_valid && !@io_out_ready")]
for k in range(8):
    higher = " && ".join(["!@io_in_%d_valid" % j for j in range(k)]) or "1"
    COV.append(("win%d" % k, "@io_in_%d_valid && %s" % (k, higher)))

PAIRS = [Pair("Arbiter8_MainPipeReq", "a_", clocked=False, stim=STIM, cov=COV,
              decls=DECLS, cov_min=200)]

HEADER = """自动生成：verif/ut/Arbiter8_MainPipeReq/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
Arbiter8_MainPipeReq 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
