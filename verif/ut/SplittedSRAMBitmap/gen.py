#!/usr/bin/env python3
"""生成 SplittedSRAM（bitmap cache 阵列）的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden SplittedSRAM vs SplittedSRAM_xs，全部输出逐拍逐位比较。
存储不复位（SRAMTemplate_124 无 shouldReset），两侧 SRAM 宏的上电内容不同 —— 所以前 64 拍
（warmup，紧跟上电复位）把 32 组 × 4 路全部写一遍（waymask 全 1、读口关），之后才开始比。
之后的激励：
  * 读写各约一半（同拍读写同组也会发生）；waymask 逐位随机（含跨 waySplit 组的 4'b0110 之类）；
  * MBIST / SRAM 控制 DFT 口 15/16 时间钉 0、其余时间随机（4 块各自一套口，接错块号立刻读出不同）；
  * 上电后不再打 reset（SRAM 内容不受 reset 影响，中途 reset 只会让 tb 更难 arm，没有额外覆盖）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

DFT = [n for d, w, n in golden_ports("SplittedSRAM")
       if d == "input" and (n.startswith("boreChildrenBd_") or n.startswith("sigFromSrams_"))
       and not n.endswith(("_addr", "_addr_rd", "_wdata"))]

STIM = ["if (cyc < 72) begin   // 上电填表：每拍写一组、4 路全写",
        "  @io_w_req_valid = 1'b1;",
        "  @io_w_req_bits_setIdx = 5'(cyc);",
        "  @io_w_req_bits_waymask = 4'hF;",
        "  @io_r_req_valid = 1'b0;",
        "end",
        "if (cyc < 72 || s_mode != 0) begin"]
for d in DFT:
    STIM.append("  @%s = '0;" % d)
STIM.append("end")

COV = [
    ("read", "@io_r_req_valid"),
    ("write", "@io_w_req_valid"),
    ("rw_same_set", "@io_r_req_valid && @io_w_req_valid && @io_r_req_bits_setIdx == @io_w_req_bits_setIdx"),
    ("wmask_cross", "@io_w_req_valid && @io_w_req_bits_waymask == 4'b0110"),
    ("dft_active", "s_mode == 0"),
]

PAIRS = [Pair("SplittedSRAM", "s_", clocked=True, stim="\n".join(STIM), cov=COV,
              reset_period=0, mode_period=2000, warmup=72, cov_min=50)]

HEADER = """自动生成：verif/ut/SplittedSRAMBitmap/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
SplittedSRAM（bitmap cache 阵列）双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
