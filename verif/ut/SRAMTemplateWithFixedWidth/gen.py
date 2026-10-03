#!/usr/bin/env python3
"""生成 SRAMTemplateWithFixedWidth 家族 4 个变体的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

四对：golden <V> vs <V>_xs，全部输出逐拍逐位比较。内层 SRAMTemplate 带 shouldReset（复位后用
256 拍把 256 组清零，期间读写不 ready）与 holdRead（读出数据保持到下次读）——所以：
  * reset 只偶尔打（约每 20000 拍一次），给清表留时间；上电后先等 300 拍（warmup）；
  * 读出保持寄存器不复位：第一次读请求之后再等 2 拍才开始比（arm）。
激励：set 下标 3/4 时间挤在 16 组里（写过的组很快被读到）、其余全随机；读写各约一半（单口，
写优先压读也会发生）；MBIST / SRAM 控制 DFT 口 15/16 时间钉 0、其余随机。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

VARIANTS = [("SRAMTemplateWithFixedWidth", "f0_"), ("SRAMTemplateWithFixedWidth_4", "f4_"),
            ("SRAMTemplateWithFixedWidth_12", "f12_"), ("SRAMTemplateWithFixedWidth_28", "f28_")]


def stim(top, x):
    dft = [n for d, w, n in golden_ports(top)
           if d == "input" and (n.startswith("boreChildrenBd_") or n.startswith("sigFromSrams_"))
           and not n.endswith(("_addr", "_addr_rd", "_wdata"))]
    s = ["if (%smode < 12) begin" % x,
         "  @io_r_req_bits_setIdx = 8'($urandom_range(0, 15));",
         "  @io_w_req_bits_setIdx = 8'($urandom_range(0, 15));",
         "end",
         "if (%smode != 0) begin" % x]
    s += ["  @%s = '0;" % d for d in dft]
    s.append("end")
    return "\n".join(s)


COV = [
    ("read", "@io_r_req_valid"),
    ("write", "@io_w_req_valid"),
    ("rw_same", "@io_r_req_valid && @io_w_req_valid"),
    ("reset_mid", "@reset && cyc > 1000"),
]

PAIRS = [Pair(top, x, clocked=True, stim=stim(top, x), cov=COV,
              reset_period=20000, mode_period=2000, warmup=300, cov_min=5,
              arm=["@io_r_req_valid"], arm_delay=2)
         for top, x in VARIANTS]

HEADER = """自动生成：verif/ut/SRAMTemplateWithFixedWidth/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
SRAMTemplateWithFixedWidth 家族 4 变体双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
