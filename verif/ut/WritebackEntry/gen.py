#!/usr/bin/env python3
"""生成 WritebackEntry / WritebackEntry_15 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

两对：golden WritebackEntry vs WritebackEntry_xs、golden WritebackEntry_15 vs WritebackEntry_15_xs，
全部输出逐拍逐位比较。激励偏置：
  * req_valid / primary_valid 各约 3/4，hasData / voluntary 各一半 ⇒ ProbeAck/ProbeAckData/
    Release/ReleaseData 四种报文都走到；
  * mem_release_ready 一半 ⇒ 发送阶段常被背压；mem_grant_valid 1/4 ⇒ S_RELEASE_RESP 要等若干拍。
不复位的数据/地址寄存器：第一次 alloc 之后再等 2 拍（行数据晚一拍写入）才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
@io_req_valid = ($urandom_range(0, 3) != 0);
@io_primary_valid = ($urandom_range(0, 3) != 0);
@io_mem_grant_valid = ($urandom_range(0, 3) == 0);
"""


def cov(x):
    return [
        ("alloc", "@io_req_valid && @io_primary_valid && @io_primary_ready"),
        ("probeack", "@io_mem_release_valid && @io_mem_release_ready && @io_mem_release_bits_opcode == 3'd4"),
        ("probeackdata", "@io_mem_release_valid && @io_mem_release_ready && @io_mem_release_bits_opcode == 3'd5"),
        ("release", "@io_mem_release_valid && @io_mem_release_ready && @io_mem_release_bits_opcode == 3'd6"),
        ("releasedata", "@io_mem_release_valid && @io_mem_release_ready && @io_mem_release_bits_opcode == 3'd7"),
        ("release_stall", "@io_mem_release_valid && !@io_mem_release_ready"),
        ("wait_grant", x + "u_gold.state == 2'd2 && !@io_mem_grant_valid"),
        ("grant_done", x + "u_gold.state == 2'd2 && @io_mem_grant_valid"),
        ("reset_mid", "@reset && cyc > 100"),
    ]


PAIRS = [
    Pair(top, pfx, clocked=True, stim=STIM, cov=cov(pfx),
         reset_period=2000, cov_min=50,
         # opcode 最高位恒 1（{1, voluntary, hasData}）；5 位 id 变体的 source 最高位恒 0（零扩展）
         exempt=["io_mem_release_bits_opcode[2]"] + (["io_mem_release_bits_source[5]"] if top == "WritebackEntry" else []),
         arm=["@io_req_valid && @io_primary_valid && @io_primary_ready"], arm_delay=2)
    for top, pfx in (("WritebackEntry", "w0_"), ("WritebackEntry_15", "w15_"))
]

HEADER = """自动生成：verif/ut/WritebackEntry/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
WritebackEntry / WritebackEntry_15 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
