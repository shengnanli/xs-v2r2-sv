# vmucp 白名单条目：SRT16DividerDataModule（2026-10-03，agent/rob-regcache，本 lane 实测）
#
# ---- 基线（诊断跑，diagnostic-full 口径，vmucp=false，FM_MERGE_DUP=false，verif/ut/SRT16DividerDataModule）----
#   native SUCCEEDED / passing 1797 / failing 0 / unmatched 全 0 / unread 6（全部 matched_nc，FM 自己按名配上）：
#     r:/WORK/SRT16DividerDataModule/aLZCReg_reg[6]       <-> i:/WORK/SRT16DividerDataModule/u_core/aLZCReg_reg[6]
#     r:/WORK/SRT16DividerDataModule/dLZCReg_reg[6]       <-> i:/WORK/SRT16DividerDataModule/u_core/dLZCReg_reg[6]
#     r:/WORK/SRT16DividerDataModule/udNegReg_0_reg[67]   <-> i:/WORK/SRT16DividerDataModule/u_core/udNegReg_0_reg[67]
#     r:/WORK/SRT16DividerDataModule/udNegReg_1_reg[67]   <-> i:/WORK/SRT16DividerDataModule/u_core/udNegReg_1_reg[67]
#     r:/WORK/SRT16DividerDataModule/udNegReg_3_reg[67]   <-> i:/WORK/SRT16DividerDataModule/u_core/udNegReg_3_reg[67]
#     r:/WORK/SRT16DividerDataModule/udNegReg_4_reg[67]   <-> i:/WORK/SRT16DividerDataModule/u_core/udNegReg_4_reg[67]
#
# 这 6 位是什么（golden 自带死位，重写照留以保持 bug-for-bug，见 rtl 文件头"寄存器怪癖"）：
#   · aLZCReg / dLZCReg 是 7 位（Scala aLZC 宽 lzc_width+1），写入恒为 {1'b0, 6 位 LZC}，
#     全部读者只取 [5:0]（lzcRegDiff 与 RightShifter.io_shiftNum）⇒ bit 6 无读者；
#   · udNegReg_{0,1,3,4} 是 68 位，读者只取 [65:0]（宽 CSA）与 [66:57]（推测块 CSA）⇒ bit 67 无读者。
#   与 verif/fm_target_config/DivUnit.tcl 是同一批位（那里在父级 DivUnit 内、golden 孩子两侧同源）。
#
# ---- standing rule 六条 ----
# 1 精确绑定：6 对由 FM 按名配上（unread_points.txt 全为 matched_nc，恰为上述 6 对，无 unmatched unread）。
# 2 双射：同名同位，一一对应。
# 3 passing 正好增 unread 数：1797 -> 1803（+6）（official 复核判据）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无黑盒（CSA3_2_* ×31、RightShifter 两侧白盒）。
# 6 摘要：本文件 + docs/lanes/rob-regcache_prereg.md §B.3。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 6 位。

fm_target_vmucp_allow
