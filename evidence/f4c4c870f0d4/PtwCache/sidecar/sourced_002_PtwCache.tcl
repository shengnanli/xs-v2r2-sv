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

#
# ---- 2026-10-11 更新（agent/l2tlb-gc，codex 0222/0228）----
# FM 输入改为：impl 读 SRAM 一路重写件（SplittedSRAM_1/2、SRAMTemplate_128/129/143），两侧共读登记 MC 存储层
# （sram_array_*_ptw_l0/l1、array_10/11），array_10_ext/array_11_ext 两侧都不读（对称未解析黑盒）。于是：
#   · 上面 matched_nc 20 里的 17 个 array_1x_ext/reg_RW0_ren 随 ext 黑盒化消失（ext 内部不再展开）；
#   · unmatched unread 实测 41↔41（evidence/882209fe5798/PtwCache，钉点脚本字面计数处 fail-closed 停下的那一跑），
#     五族规则逐条解析为 A32/B4/C4/D1/E0，见 verif/ut/PtwCache/fm_pins.tcl 的 _expect 处。
# ★复核判据（本轮）★：钉点后 unmatched 六项全零、failing 0、unread 0；passing 恰等于 fm_predict 模型
#   26599 减 constant_reg（模型 = regs 21088 + outs 2714 + 黑盒输入 2797，ext 当黑盒正是本轮证明形态）。
#   matched_nc 的实际条数与双射核对写进 docs/lanes/l2tlb-gc_prereg.md。passing 偏离模型即停下诊断。
fm_target_vmucp_allow
