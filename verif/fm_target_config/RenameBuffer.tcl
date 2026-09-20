# vmucp 白名单条目：RenameBuffer
#
# 本文件 = RenameBuffer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   RenameBuffer(2026-09-17 加): 51 个 unread 点，钉点后全部转成 matched_nc
#          (verif/ut/RenameBuffer/fm_pins.tcl，钉前 unmatched unread 51(51)、
#          钉后六项 unmatched 全零、matched_unread_notcompared_pairs = 51)。
#          ★注意本目标同时开着 FM_MERGE_DUP=false★（Makefile 里有完整依据）——
#          那一项把 native FAILED 翻成 SUCCEEDED、passing 651 -> 5825、
#          failing 20 -> 0、unverified 5147 -> 0，是本轮最大的一次"加强"。
#          51 点分三族，两侧同为死位：
#            A  5 点  deqPtrVec_1..5 的 flag —— deqPtrVec **只有 head(0 号) 有读者**
#            B 40 点  同上的 value[0..7]        (numValidEntries 与 deqPtrNext 都只取 0 号；
#                     提交读口走 deqPtrOH 那个 one-hot 影子寄存器，不看 deqPtrVec)。
#                     golden 留着 1..5 是因为 Rab.scala 末尾 dontTouch(deqPtrVec)。
#            C  6 点  toVecExcpMod preg 的 bit7 —— 打拍寄存器存 8 位 pdest，
#                     而输出端口只有 7 位，golden 自己写的就是 preg_r[6:0]，
#                     bit7 从来没有读出路径。重写核 bug-for-bug 照抄。
#          ★把核收窄成"只留 head"反而制造不对称★：golden 那 45 位会变成
#          golden-only 死位，更难签 —— 与 TLBFA 那条"不要收窄 reqVpn"同一结论。
#          ★复核判据★: passing 5825 -> 5876(正好 +51)、failing 仍 0、unread 归 0、
#          unmatched 保持全零。passing 不增即空转，不算过。

fm_target_vmucp_allow
