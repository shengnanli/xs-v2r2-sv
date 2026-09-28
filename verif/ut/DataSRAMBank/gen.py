#!/usr/bin/env python3
"""生成 DataSRAMBank 家族（DataSRAMBank / _1 / _2 / _4）的双例化 UT testbench（tb.sv）。

四对各自双例化（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位比全部输出。
每路 SRAMTemplate_N 两侧白盒（golden 侧 golden 件、重写侧 rtl/common 重写件），其下宏包装与
厂商行为模型 array_7_ext.v 两侧同一份。
激励：set 下标压到 0..7 让读写撞组；写的 way_en 3/4 概率独热、1/4 随机（覆盖"写多路"检查）；
MBIST / SRAM 控制在 mode 0..11 恒 0，12..15 全随机（MBIST 读写地址同样压到 0..7）。
SRAM 阵列与读出锁存不复位且无上电清零：先用 mode 0 阶段把 0..7 组各路写满再比——arm 条件是
"每一路都被写过"（粘滞）+ 读过一次，之后再等 2 拍。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

VARIANTS = [("DataSRAMBank", "db0_"), ("DataSRAMBank_1", "db1_"), ("DataSRAMBank_2", "db2_"),
            ("DataSRAMBank_4", "db4_")]


def stim(top):
    mb = [n for d, _, n in golden_ports(top)
          if d == "input" and (n.startswith("boreChildrenBd") or n.startswith("sigFromSrams"))]
    return "\n".join(
        ["@io_r_addr = 8'($urandom_range(0, 7));",
         "@io_w_addr = 8'($urandom_range(0, 7));",
         "if ($urandom_range(0, 3) != 0) @io_w_way_en = 4'b0001 << $urandom_range(0, 3);",
         "if (cyc < 400) begin @io_w_en = 1'b1; @io_w_way_en = 4'b0001 << (cyc % 4); "
         "@io_w_addr = 8'((cyc / 4) % 8); end",
         "if (@mode < 12 || cyc < 400) begin"] + [f"  @{n} = '0;" for n in mb] + ["end"] +
        # MBIST 读写地址也压到 0..7：阵列没有上电清零，读到没写过的组两侧（各自随机初值）必然不同
        [f"@{n} = 9'($urandom_range(0, 7));" for n in mb if n.endswith("_addr") or n.endswith("_addr_rd")])


PAIRS = []
for top, pfx in VARIANTS:
    PAIRS.append(Pair(
        top, pfx, clocked=True, stim=stim(top),
        cov=[("multi_way_write", "@io_w_en && !$onehot0(@io_w_way_en)"),
             ("read", "@io_r_en"),
             ("mbist_we", "@boreChildrenBd_bore_we")],
        mode_period=3000, reset_period=40000, cov_min=200, arm_delay=2,
        arm=["cyc >= 400", "@io_r_en"]))

HEADER = """自动生成：verif/ut/DataSRAMBank/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
DataSRAMBank 家族 4 对双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
