#!/usr/bin/env python3
"""生成 DuplicatedTagArray 的双例化 UT testbench（tb.sv）。

golden DuplicatedTagArray vs 重写 DuplicatedTagArray_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
每拍逐位比全部输出（16 个 43 位 tag 读出、io_read_3_ready、MBIST 回读）。
子模块两侧白盒：golden 侧 TagArray/TagSRAMBank/SRAMTemplate_116/MbistPipeDcacheTag 用 golden，
重写侧用本仓重写件；其下厂商宏行为模型两侧同一份。
激励：4 个读口各半数 valid、set 下标压到 0..15；写 1/3 概率；MBIST / SRAM 控制在 mode 0..11 恒 0，
12..15 全随机。arm：4 份副本上电清零完成且 4 个读口都读过一次之后再等 2 拍（读出锁存不复位）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

TOP = "DuplicatedTagArray"
mb = [n for d, _, n in golden_ports(TOP)
      if d == "input" and (n.startswith("boreChildrenBd") or n.startswith("sigFromSrams"))]
STIM = "\n".join(
    [f"@io_read_{i}_bits_idx = 8'($urandom_range(0, 15));" for i in range(4)] +
    ["@io_write_bits_idx = 8'($urandom_range(0, 15));",
     "@io_write_valid = ($urandom_range(0, 2) == 0);",
     "if (@mode < 12) begin"] + [f"  @{n} = '0;" for n in mb] + ["end"])

G = "dta_u_gold."
COV = [
    ("write", "@io_write_valid"),
    ("read3_blocked", "@io_read_3_valid && !@io_read_3_ready"),
    ("mbist_req", "@boreChildrenBd_bore_req"),
    ("ecc_nonzero", "@io_write_valid && (^@io_write_bits_tag)"),
]

PAIRS = [
    Pair(TOP, "dta_", clocked=True, stim=STIM, cov=COV,
         mode_period=3000, reset_period=40000, cov_min=200, arm_delay=2,
         arm=[G + "array_0.tag_arrays_0.rst_cnt[8]"] +
             [f"@io_read_{i}_valid && {G}array_{i}.tag_arrays_1.io_read_ready" for i in range(4)]),
]

HEADER = """自动生成：verif/ut/DuplicatedTagArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
DuplicatedTagArray 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
