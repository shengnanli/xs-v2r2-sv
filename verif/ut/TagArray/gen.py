#!/usr/bin/env python3
"""生成 TagArray 目录的双例化 UT testbench（tb.sv）：TagSRAMBank / TagArray 两对。

golden <Top> vs 重写 <Top>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位比全部输出。
两侧存储体下面是同一套 SRAMTemplate_116（重写侧用本仓 SRAMTemplate_116 + xs_SRAMTemplate_core）
与同一份厂商宏行为模型（sram_array_* / array_8 / array_8_ext.v）。
激励：读写各半数 valid、set 下标压到 0..15 让读写撞同一组；MBIST / SRAM 控制穿线端口
在 mode 0..11 恒 0（正常工作），mode 12..15 全随机（MBIST 读写、hold/bypass 等都走一遍）。
arm：上电逐组清零（rst_cnt 计满 256）之后、且出现过一次读之后再等 2 拍才比——SRAM 阵列与读出锁存
不复位，+random 档两侧初值不同。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402


def quiet_mbist(top):
    """mode < 12 时把 bore*/sigFromSrams* 输入全清 0"""
    names = [n for d, _, n in golden_ports(top)
             if d == "input" and (n.startswith("boreChildrenBd") or n.startswith("sigFromSrams"))]
    L = ["if (@mode < 12) begin"]
    L += [f"  @{n} = '0;" for n in names]
    L.append("end")
    return "\n".join(L)


COMMON = """
@io_read_bits_idx = 8'($urandom_range(0, 15));
@io_write_bits_idx = 8'($urandom_range(0, 15));
@io_write_valid = ($urandom_range(0, 2) == 0);
"""

TSB_COV = [
    ("sweep", "!tsb_u_gold.rst_cnt[8]"),
    ("read_fire", "@io_read_valid && @io_read_ready"),
    ("read_blocked", "@io_read_valid && !@io_read_ready"),
    ("write_way0", "@io_write_valid && @io_write_bits_way_en == 2'b01"),
]
TA_COV = [
    ("read_fire", "@io_read_valid && @io_read_ready"),
    ("write_hi", "@io_write_valid && @io_write_bits_way_en[3]"),
]

PAIRS = [
    Pair("TagSRAMBank", "tsb_", clocked=True, stim=COMMON + quiet_mbist("TagSRAMBank"), cov=TSB_COV,
         mode_period=3000, reset_period=40000, cov_min=200,
         arm=["tsb_u_gold.rst_cnt[8]", "@io_read_valid && @io_read_ready"], arm_delay=2),
    Pair("TagArray", "ta_", clocked=True, stim=COMMON + quiet_mbist("TagArray"), cov=TA_COV,
         mode_period=3000, reset_period=40000, cov_min=200,
         arm=["ta_u_gold.tag_arrays_0.rst_cnt[8]", "@io_read_valid && @io_read_ready"], arm_delay=2),
]

HEADER = """自动生成：verif/ut/TagArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
TagSRAMBank / TagArray 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
