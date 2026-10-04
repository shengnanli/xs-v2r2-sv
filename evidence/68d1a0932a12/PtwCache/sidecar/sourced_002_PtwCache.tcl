# vmucp 白名单条目：PtwCache
#
# 本文件 = PtwCache 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-27，agent/ptwcache3；实测 evidence/6a102f7a5101/PtwCache/）----
# 第 3 轮 signoff-strict（FM_MERGE_DUP=false，黑盒边界空、SRAM 一路两侧同源 golden）：
#   native SUCCEEDED / passing 143717 / failing 0 / unverified 0 / unmatched 比较点 0(0) /
#   dont_verify 无 / 黑盒 0；唯一卡点 unread = matched_nc 20 对 + unmatched unread ref 60 / impl 61。
# 80 个点的来源（两侧同为死位，不是哪一侧漏了逻辑）：
#   matched_nc 20：17 个 SRAM 叶子 array_1x_ext/reg_RW0_ren（golden .v 在 SYNTHESIS 下 RW0_rdata
#     直接取 ram[reg_RW0_addr]，ren 无读者；两侧同一份文件）+ resp_res_l{1,2,3}_pre
#     （io_resp_bits_prefetch 只取 sp/l0 那一路，l1/l2/l3 的 pre 无读者；重写核照抄）。
#   unmatched unread 60（钉点后转 matched_nc，五族，见 verif/ut/PtwCache/fm_pins.tcl 头）：
#     A 32 l2/l3 表项 prefetch 位；B 4 hitPre/l2Pre/l3Pre 打拍；C 4 l1 读出 prefetch 打拍；
#     D 8 wakeup tag[8:3]/way_info[0]；E 12 MBIST 分发级地址寄存器位。
#   impl 独有 1 个（sp_hitdata_ck[prefetch]）已在 RTL 消掉 —— 消掉之后 ref 60 == impl 60 才有双射。
# ★复核判据★：钉点后 unmatched 六项全零、matched_unread_notcompared_pairs = 80，
#   打开本项后 passing 143717 -> 143797（正好 +80）、failing 仍 0、unread 归 0。
#   passing 不增即空转，不算过。

fm_target_vmucp_allow
