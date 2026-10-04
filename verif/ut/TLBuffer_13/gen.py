#!/usr/bin/env python3
"""生成 TLBuffer_13 的双例化 UT testbench（tb.sv）：golden TLBuffer_13 vs 重写 TLBuffer_13_xs
（scripts/dual_tb_lib.py），每拍逐位比较全部 374 端口里的输出。
impl 侧闭包 = rtl/memblock/TLBuffer_13.sv（手写 bank + 生成 wrapper）+ 已签重写队列
Queue2_TLBundle{A_19,B_1,C_1,D_20,E_1}（+ xs_ChiselQueue_core）；ram_* 两侧同源。
激励偏置：每个 bank、每个通道的 valid/ready 按 mode 分"畅通 / 下游堵 / 全随机"，保证
20 个队列满、空、同拍进出都走到。
arm：ram 行为模型不复位，deq_bits 在队列空时也直接读 ram[deq_ptr]；两侧上电初值不同
（initreg random）时，只有两个表项都被写过一次之后输出才确定。所以 20 个队列各要求在
ptr=0 / ptr=1 上各入队过一次（看 golden 的 wrap = 入队指针）再开始比（40 个 arm 条件）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "tlb_u_gold."
# (通道, golden 实例基名, enq valid 端口, enq ready 端口, deq valid 端口, deq ready 端口或 None)
CH = [
    ("a", "nodeOut_a_q", "auto_in_{b}_a_valid", "auto_in_{b}_a_ready", "auto_out_{b}_a_valid", "auto_out_{b}_a_ready"),
    ("b", "nodeIn_b_q", "auto_out_{b}_b_valid", "auto_out_{b}_b_ready", "auto_in_{b}_b_valid", "auto_in_{b}_b_ready"),
    ("c", "nodeOut_c_q", "auto_in_{b}_c_valid", "auto_in_{b}_c_ready", "auto_out_{b}_c_valid", "auto_out_{b}_c_ready"),
    ("d", "nodeIn_d_q", "auto_out_{b}_d_valid", "auto_out_{b}_d_ready", "auto_in_{b}_d_valid", "auto_in_{b}_d_ready"),
    ("e", "nodeOut_e_q", "auto_in_{b}_e_valid", "auto_in_{b}_e_ready", "auto_out_{b}_e_valid", None),
]


def inst(base, b):
    return base if b == 0 else f"{base}_{b}"


stim = ["case (@mode % 3)"]
for mode, (pv, pr) in ((0, ("($urandom_range(0, 1) == 0)", "($urandom_range(0, 7) != 0)")),
                       (1, ("($urandom_range(0, 3) != 0)", "($urandom_range(0, 3) == 0)"))):
    stim.append(f"  {mode}: begin")
    for b in range(4):
        for _, _, ev, _, _, dr in CH:
            stim.append(f"    @{ev.format(b=b)} = {pv};")
            if dr:
                stim.append(f"    @{dr.format(b=b)} = {pr};")
    stim.append("  end")
stim.append("  default: ;")
stim.append("endcase")
STIM = "\n".join(stim)

ARM, COV = [], []
for b in range(4):
    for ch, base, ev, er, dv, dr in CH:
        q = G + inst(base, b)
        ARM.append(f"{q}.do_enq && !{q}.wrap")
        ARM.append(f"{q}.do_enq && {q}.wrap")
        if dr:  # E 出口 ready 恒 1：每拍都能出队，2 项队列永远满不了（见 EXEMPT）
            COV.append((f"b{b}_{ch}_full_stall", f"@{ev.format(b=b)} && !@{er.format(b=b)}"))
        if dr:
            COV.append((f"b{b}_{ch}_enq_deq_same", f"{q}.do_enq && {q}.do_deq"))
        else:
            COV.append((f"b{b}_{ch}_enq_deq_same", f"{q}.do_enq && @{dv.format(b=b)}"))

# 常量输出（golden 队列写 ram 的常量位，见 rtl/memblock/TLBuffer_13.sv 各通道注释）：
#   B 出口 size=6 / source=0 / mask=全1 / corrupt=0；D 出口 size=6。它们不可能见过 0 和 1。
# E 入口 ready：E 队列出口 ready 恒 1（golden 无该端口），每拍出队，2 项队列满不了，ready 恒 1。
EXEMPT = [f"auto_in_{b}_{f}" for b in range(4)
          for f in ("b_bits_size", "b_bits_source", "b_bits_mask", "b_bits_corrupt", "d_bits_size",
                    "e_ready")]
PAIRS = [Pair("TLBuffer_13", "tlb_", clocked=True, stim=STIM, cov=COV, arm=ARM, exempt=EXEMPT)]
HEADER = """
tb —— TLBuffer_13：L2Top.inner_buffer（4 路 TL-C 五通道缓冲）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
