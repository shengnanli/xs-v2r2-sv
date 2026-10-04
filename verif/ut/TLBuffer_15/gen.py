#!/usr/bin/env python3
"""生成 TLBuffer_15 的双例化 UT testbench（tb.sv）：golden TLBuffer_15 vs 重写 TLBuffer_15_xs
（scripts/dual_tb_lib.py），每拍逐位比较全部输出。
impl 侧闭包 = 已签共享核 xs_TLBuffer_ad_core + 已签重写队列 Queue2_TLBundle{A_12,D_13}
（+ xs_ChiselQueue_core）；ram_2x133 / ram_2x76 两侧同源。
激励偏置：A/D 两侧 valid/ready 按 mode 分"畅通 / 下游堵 / 上游稀疏"三种，保证队列满、空、
同拍进出都走到。
arm：ram 行为模型不复位，deq_bits 在队列空时也直接读 ram[deq_ptr]；两侧上电初值不同
（initreg random）时，只有两个表项都被写过一次之后输出才确定。所以 A、D 各要求在
ptr=0 / ptr=1 上各发生过一次入队（看 golden 的 wrap = 入队指针）再开始比。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
case (@mode % 3)
  0: begin  // 畅通
    @auto_in_a_valid = ($urandom_range(0, 1) == 0);
    @auto_out_a_ready = ($urandom_range(0, 7) != 0);
    @auto_out_d_valid = ($urandom_range(0, 1) == 0);
    @auto_in_d_ready = ($urandom_range(0, 7) != 0);
  end
  1: begin  // 下游堵：队列攒满
    @auto_in_a_valid = ($urandom_range(0, 3) != 0);
    @auto_out_a_ready = ($urandom_range(0, 3) == 0);
    @auto_out_d_valid = ($urandom_range(0, 3) != 0);
    @auto_in_d_ready = ($urandom_range(0, 3) == 0);
  end
  default: ;  // 全随机
endcase
"""
Q = "tlb_u_gold."
ARM = [
    f"{Q}nodeOut_a_q.do_enq && !{Q}nodeOut_a_q.wrap",
    f"{Q}nodeOut_a_q.do_enq && {Q}nodeOut_a_q.wrap",
    f"{Q}nodeIn_d_q.do_enq && !{Q}nodeIn_d_q.wrap",
    f"{Q}nodeIn_d_q.do_enq && {Q}nodeIn_d_q.wrap",
]
COV = [
    ("a_fire_in", "@auto_in_a_valid && @auto_in_a_ready"),
    ("a_fire_out", "@auto_out_a_valid && @auto_out_a_ready"),
    ("d_fire_in", "@auto_out_d_valid && @auto_out_d_ready"),
    ("d_fire_out", "@auto_in_d_valid && @auto_in_d_ready"),
    ("a_full_stall", "@auto_in_a_valid && !@auto_in_a_ready"),
    ("d_full_stall", "@auto_out_d_valid && !@auto_out_d_ready"),
    ("a_enq_deq_same", f"{Q}nodeOut_a_q.do_enq && {Q}nodeOut_a_q.do_deq"),
    ("d_enq_deq_same", f"{Q}nodeIn_d_q.do_enq && {Q}nodeIn_d_q.do_deq"),
]
PAIRS = [Pair("TLBuffer_15", "tlb_", clocked=True, stim=STIM, cov=COV, arm=ARM)]
HEADER = """
tb —— TLBuffer_15：L2Top 的 64 位 TL-UL A/D 两通道缓冲（inner_i_mmio_buffer / inner_buffers*）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
