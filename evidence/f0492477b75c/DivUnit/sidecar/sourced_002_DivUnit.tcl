# vmucp 白名单条目：DivUnit
#
# 契约见 verif/fm_target_config/README.md：只许注释、fm_target_vmucp_allow、
# fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
#   unread 点是两侧共用 golden 孩子 SRT16DividerDataModule 内部的死位，
#   两侧同一份源（receipt 闭包 sha256 相同）、同死，各 6 位、逐位同名：
#       ref  r:/WORK/DivUnit/divDataModule/{aLZCReg_reg[6], dLZCReg_reg[6],
#            udNegReg_0_reg[67], udNegReg_1_reg[67], udNegReg_3_reg[67],
#            udNegReg_4_reg[67]}
#       impl i:/WORK/DivUnit/u_core/u_div/{同名 6 位}
#   成因（golden 自带死位，与重写无关，位索引可机械复核）：
#     · aLZCReg/dLZCReg 是 reg [6:0]，赋值恒为 {1'h0, 6 位 LZC}（bit6 恒 0），
#       全部读者只取 [5:0]（golden SRT16DividerDataModule.sv 的
#       _lzcRegDiff_T_4 与 RightShifter.io_shiftNum）→ bit 6 无读者。
#     · udNegReg_{0,1,3,4} 是 reg [67:0]，全部读者只取 [65:0] 或
#       [66]/[66:57]（qPrevReg/qNext_sel 选择向量与 csa io_in_2）→ bit 67 无读者。
#   这 6 对点属 unmatched unread（两侧层次名不同 divDataModule vs
#   u_core/u_div，无扇出签名可配，FM 名匹配配不上），按 fm_eq.tcl 的
#   既定处置先由 verif/ut/ArithVecLeaves5/fm_pins.tcl 逐对 set_user_match
#   钉死（双射、fail-closed），再交 vmucp 实比 —— 加强，不是放过。
#   双射核对（FM_MERGE_DUP=false 下，证据 /tmp 诊断跑 B 与 fm_work 复跑）：
#   unread_points.txt ref/impl 各恰 6 行，叶名集合逐字相同，无 matched_nc 项。
#   ★复核判据★：unread 6 -> 0，且 passing 恰好 +6（3126 -> 3132）。
#   passing 不增即空转，不算过。

fm_target_vmucp_allow
