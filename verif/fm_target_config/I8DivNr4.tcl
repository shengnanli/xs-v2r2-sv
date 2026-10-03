# vmucp 白名单条目：I8DivNr4（2026-10-03，agent/srt-divblocks，本 lane 实测）
#
# ---- 基线（诊断跑，signoff-strict 口径，vmucp=false，verif/ut/I8DivNr4，commit a5e76872）----
#   native SUCCEEDED / passing 106 / failing 0 / unmatched compare points 0 /
#   constant reg 1 / 4(4) unmatched unread：
#     r:/WORK/I8DivNr4/const_d_reg_<k>_reg[9]  <->  i:/WORK/I8DivNr4/u_core/const_d_reg_reg[<k>][9]，k=0..3
# 加钉点（verif/ut/I8DivNr4/fm_pins_pre.tcl，4/4 pinned）后再跑：passing 106 / unread 4，
#   native_facts.matched_unread_notcompared_pairs 恰为上面 4 对、unmatched 各项全 0。
#
# ---- standing rule 六条 ----
# 1 精确绑定：4 对路径逐字列在 fm_pins_pre.tcl，返回值计数 + 字面守卫 4。
# 2 双射：k↔k，同一档除数倍数寄存器的同一位（bit 9）；两侧都是 10 位字段只读低 9 位
#   （golden `.io_d_cons_k(const_d_reg_k[8:0])`，POST 只读 const_d_reg_1/2[7:0]），死因相同。
# 3 passing 正好增 unread 数：106 -> 110（+4）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无新黑盒（本目标零黑盒，child IterBlockI8Nr4 两侧白盒）。
# 6 摘要：本文件 + docs/lanes/srt-divblocks_prereg.md §5。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 4 位，不记作 Not-Compared。
# 跑前登记的复核判据：passing 110 / failing 0 / unread 0 / unmatched 全 0 / constant reg 1 /
#   fm.log 出现 "I8DIVNR4_PINS: dead const_d_reg_k[9] 4 / 4 points pinned"。

fm_target_vmucp_allow
