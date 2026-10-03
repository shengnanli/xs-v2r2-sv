#!/usr/bin/env python3
"""生成 FrontendTrigger 的双例化 UT testbench（tb.sv）。

golden FrontendTrigger vs 重写 FrontendTrigger_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
每拍逐位比较 16 个 io_triggered。
激励：16 个 pc 按取指包的真实形态给（pc[i] = pc[0] + 2*i），pc[0] 与写进触发器的 tdata2 都落在
  同一个随机基址附近 ±64 / ±12 字节（按 mode 两档；每 200 拍换基址），让 EQ/GE/LT 三种比较都在边界两侧来回；
  基址的低 6 位随机，所以包内高位进位（carry）自然出现。1/16 的拍 pc 全随机（不连续的包，
  golden 对它也有定义，照比）。chain / select / debugMode 压低，matchType 四个值均匀（含不支持的 1）。
覆盖：三种动作输出、三种 matchType 命中、带 carry 的命中、链尾命中（前一个 chain=1 且两者都 hit）、
  链被前一个未命中挡住、select / debugMode 挡住。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [49:0] ft_base = '0;
logic [49:0] ft_pc0;
int unsigned ft_span;
"""

STIM = "\n".join([
    "if (cyc % 200 == 0) ft_base = 50'({$urandom, $urandom});",
    "ft_span = (@mode % 2) ? 12 : 64;",
    "ft_pc0 = ft_base + 50'($urandom_range(0, 2 * ft_span)) - 50'(ft_span);",
    "if ($urandom_range(0, 15) != 0) begin",
] + ["  @io_pc_%d = ft_pc0 + 50'd%d;" % (i, 2 * i) for i in range(16)] + [
    "end",
    "@io_frontendTrigger_tUpdate_valid = ($urandom_range(0, 7) == 0);",
    "@io_frontendTrigger_tUpdate_bits_tdata_tdata2 = {14'($urandom), ft_base + 50'($urandom_range(0, 2 * ft_span)) - 50'(ft_span)};",
    "@io_frontendTrigger_tUpdate_bits_tdata_chain = ($urandom_range(0, 3) == 0);",
    "@io_frontendTrigger_tUpdate_bits_tdata_select = ($urandom_range(0, 7) == 0);",
    "@io_frontendTrigger_tUpdate_bits_tdata_action = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1));",
    "if (@mode % 4 == 1) @io_frontendTrigger_tUpdate_bits_tdata_matchType = 2'd0;",
    "@io_frontendTrigger_debugMode = ($urandom_range(0, 15) == 0);",
    "if (@mode % 4 != 0) begin",
    "  @io_frontendTrigger_tEnableVec_0 = 1'b1; @io_frontendTrigger_tEnableVec_1 = 1'b1;",
    "  @io_frontendTrigger_tEnableVec_2 = 1'b1; @io_frontendTrigger_tEnableVec_3 = 1'b1;",
    "end",
])

G = "ft_u_gold."
COV = [
    ("act_debug", "@io_triggered_5 == 4'h1"),
    ("act_bkpt", "@io_triggered_5 == 4'h0"),
    ("act_none", "@io_triggered_5 == 4'hF"),
    ("bkpt_blocked", "(%striggerCanFireVec_5_0 && %stdataVec_0_action == 4'h0) && !@io_frontendTrigger_triggerCanRaiseBpExp" % (G, G)),
    ("hit_eq", "%striggerHitVec_9_1 && %stdataVec_1_matchType == 2'h0" % (G, G)),
    ("hit_ge", "%striggerHitVec_9_1 && %stdataVec_1_matchType == 2'h2" % (G, G)),
    ("hit_lt", "%striggerHitVec_9_1 && %stdataVec_1_matchType == 2'h3" % (G, G)),
    ("napot_nohit", "%stdataVec_1_matchType == 2'h1 && %striggerEnableVec_1" % (G, G)),
    ("carry_hit", "%striggerHitVec_6_2 && (@io_pc_6[5] != @io_pc_0[5])" % G),
    ("carry_eq", "%striggerHitVec_6_2 && (@io_pc_6[5] != @io_pc_0[5]) && %stdataVec_2_matchType == 2'h0" % (G, G)),
    ("chain_fire", "%striggerCanFireVec_5_2 && %stdataVec_1_chain" % (G, G)),
    ("chain_block", "%striggerHitVec_5_2 && %stdataVec_1_chain && !%striggerHitVec_5_1 && !%stdataVec_2_chain" % (G, G, G, G)),
    ("chain_mid", "%striggerHitVec_5_1 && %stdataVec_1_chain" % (G, G)),
    ("select_block", "%stdataVec_0_select && %striggerEnableVec_0" % (G, G)),
    ("debug_block", "@io_frontendTrigger_debugMode && %striggerEnableVec_0" % G),
    ("update", "@io_frontendTrigger_tUpdate_valid"),
]

PAIRS = [
    Pair("FrontendTrigger", "ft_", clocked=True, stim=STIM, cov=COV, decls=DECLS,
         mode_period=500, reset_period=30000, cov_min=100),
]

HEADER = """自动生成：verif/ut/FrontendTrigger/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
FrontendTrigger 双例化逐拍比对：golden FrontendTrigger vs 重写 FrontendTrigger_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
