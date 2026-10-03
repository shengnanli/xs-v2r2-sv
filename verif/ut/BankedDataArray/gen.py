#!/usr/bin/env python3
"""生成 BankedDataArray 的双例化 UT testbench（tb.sv）。

golden BankedDataArray vs 重写 BankedDataArray_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
每拍逐位比全部输出。子模块两侧白盒：DataSRAMBank_*（本 lane）、SRAMTemplate_84..100、MbistPipeDCacheData
（PROVEN_DIRECT），其下宏包装与厂商行为模型 array_7_ext.v 两侧同一份。
激励：
  · 前 300 拍只写：把 8 bank × 4 路 × set 0..7 全部写一遍（阵列没有上电清零，读没写过的 set 两侧随机初值必不同）；
  · 之后读写/整行读随机，所有 set 下标（含 MBIST 地址）压到 0..7；bankMask 按地址与 is128 取真实值
    （一半概率），一半全随机（覆盖读-读冲突选最老）；lqIdx 值压到 0..3 让新老比较频繁翻转；
  · MBIST 在 mode 12..15 全随机，否则关；CtrlUnit 伪错误 1/8 概率。
第 300..309 拍只做整行读、can_go/stall/can_resp 全开，把 SRAM 读出锁存与整行读两级寄存写成确定值
（种子 1 × +vcs+initreg+1017 实测：不这样做时 readline 保持寄存器的随机初值会在第一次 can_resp 时漏出去）。
arm：310 拍之后、3 个读口各读过一次，再等 3 拍。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

TOP = "BankedDataArray"
mb = [n for d, _, n in golden_ports(TOP) if d == "input" and n.startswith("boreChildrenBd")]

L = []
for i in range(3):
    L += [f"@io_read_{i}_bits_addr[13:6] = 8'($urandom_range(0, 7));",
          f"@io_read_{i}_bits_addr_dup = @io_read_{i}_bits_addr;",
          f"if ($urandom_range(0, 7) == 0) @io_read_{i}_bits_addr_dup[5:3] = 3'($urandom);",
          f"@io_read_{i}_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);",
          f"@io_read_{i}_bits_lqIdx_value = 7'($urandom_range(0, 3));",
          f"if ($urandom_range(0, 1)) @io_read_{i}_bits_bankMask = @io_is128Req_{i} ? "
          f"(8'b11 << @io_read_{i}_bits_addr[5:3]) : (8'b1 << @io_read_{i}_bits_addr[5:3]);"]
L += ["@io_readline_bits_addr[13:6] = 8'($urandom_range(0, 7));",
      "@io_readline_bits_way_en = 4'b0001 << $urandom_range(0, 3);",
      "@io_readline_valid = ($urandom_range(0, 3) == 0);",
      "@io_write_valid = ($urandom_range(0, 3) == 0);"]
for b in range(8):
    L += [f"@io_write_dup_{b}_valid = @io_write_valid;",
          f"@io_write_dup_{b}_bits_addr[13:6] = 8'($urandom_range(0, 7));",
          f"@io_write_dup_{b}_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);"]
L += ["@io_pseudo_error_valid = ($urandom_range(0, 7) == 0);",
      "if (@mode < 12 || cyc < 300) begin"] + [f"  @{n} = '0;" for n in mb] + ["end",
      "@boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));",
      "@boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));",
      # 前 300 拍：顺序写满 set 0..7 × 4 路（每拍写一个 {set, way}，8 个 bank 一起），不读
      "if (cyc < 300) begin",
      "  @io_read_0_valid = 1'b0; @io_read_1_valid = 1'b0; @io_read_2_valid = 1'b0;",
      "  @io_readline_valid = 1'b0; @io_readline_intend = 1'b0;",
      "  @io_write_valid = 1'b1; @io_write_bits_wmask = 8'hFF;"]
for b in range(8):
    L += [f"  @io_write_dup_{b}_valid = 1'b1;",
          f"  @io_write_dup_{b}_bits_addr[13:6] = 8'((cyc / 4) % 8);",
          f"  @io_write_dup_{b}_bits_way_en = 4'b0001 << (cyc % 4);"]
L += ["end",
      # 300..309：只做整行读、三级握手全开——把 SRAM 读出锁存、ecc_data_delayed、readline 两级寄存全部写成确定值
      "if (cyc >= 300 && cyc < 310) begin",
      "  @io_read_0_valid = 1'b0; @io_read_1_valid = 1'b0; @io_read_2_valid = 1'b0;",
      "  @io_write_valid = 1'b0;"] + [f"  @io_write_dup_{b}_valid = 1'b0;" for b in range(8)] + [
      "  @io_readline_valid = 1'b1; @io_readline_bits_addr[13:6] = 8'(cyc % 8);",
      "  @io_readline_can_go = 1'b1; @io_readline_stall = 1'b1; @io_readline_can_resp = 1'b1;",
      "end"]
STIM = "\n".join(L)

G = "bda_u_gold."
COV = [
    ("rr_conflict", G + "rr_bank_conflict_0_1_probe || " + G + "rr_bank_conflict_1_2_probe"),
    ("rr_oldest_kill", G + "rr_bank_conflict_oldest_0 || " + G + "rr_bank_conflict_oldest_1 || " + G + "rr_bank_conflict_oldest_2"),
    ("wr_conflict", G + "wr_bank_conflict_0_probe || " + G + "wr_bank_conflict_2_probe"),
    ("rrl_conflict", G + "rrl_bank_conflict_1_probe"),
    ("readline_blocked", "@io_readline_valid && !@io_readline_ready"),
    ("read_err", "@io_read_error_delayed_0_0 || @io_read_error_delayed_1_1 || @io_read_error_delayed_2_0"),
    ("readline_err", "@io_readline_error_delayed"),
    ("pseudo_ready", "@io_pseudo_error_ready"),
    ("mbist_ack", G + "_mbistPl_mbist_ack"),
    ("is128_read", "@io_read_0_valid && @io_is128Req_0 && @io_read_0_ready"),
]

EXEMPT = []
PAIRS = [
    Pair(TOP, "bda_", clocked=True, stim=STIM, cov=COV, exempt=EXEMPT,
         mode_period=3000, reset_period=60000, cov_min=100, arm_delay=3,
         arm=["cyc >= 310",
              "@io_read_0_valid && @io_read_0_ready", "@io_read_1_valid && @io_read_1_ready",
              "@io_read_2_valid && @io_read_2_ready"]),
]

HEADER = """自动生成：verif/ut/BankedDataArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
BankedDataArray 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
