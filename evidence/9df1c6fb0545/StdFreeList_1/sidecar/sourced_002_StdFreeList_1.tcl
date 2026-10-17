# vmucp 白名单条目：StdFreeList_1
#
# 本文件 = StdFreeList_1 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-27，agent/rename lane，evidence/e9987342c6f9/StdFreeList_1 首跑) ----
#   首跑 signoff-strict、关 vmucp：native SUCCEEDED passing 890 / failing 0 / unmatched 六项全 0，
#   但 unread_notcompared = 2 → strict 判 PARTIAL(strict_unread!=0)。两个点是
#     r:/WORK/StdFreeList_1/freeRegCntReg_reg[0] <-> i:/WORK/StdFreeList_1/u_core/freeRegCntReg_reg[0]
#     r:/WORK/StdFreeList_1/freeRegCntReg_reg[1] <-> i:/WORK/StdFreeList_1/u_core/freeRegCntReg_reg[1]
#   (unread_points.txt 两行都是 matched_nc，ref/impl 侧独占各 0)。
#   ★为什么是死位、为什么只有这个变体★：freeRegCntReg 的唯一读者是四分位 perf 事件
#   (freeRegCntReg < SIZE/4、>= SIZE/4 && < SIZE/2、…)。本变体 SIZE=81，三条边界
#   81/4=20、81/2=40、81*3/4=60 恰好都是 4 的倍数，于是 `x < 20` 等价于 `x[6:2] < 5`，
#   低 2 位不进任何比较 —— golden 与重写核同一个表达式、同一个死位，两侧对称。
#   另外三个变体(158→39/79/118、21→5/10/15、31→7/15/23)的边界不是 4 的倍数，低位有读者，
#   所以它们没有 unread 点(同一批 receipt：StdFreeList 1593 / _2 336 / _3 426 均逐位等于模型)。
#   配对是 FM 自己按名配上的(matched_nc)，无 fm_pins、无人工强配。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = freeRegCntReg[1:0] 恰好 2 位。
#   (2) 双射：2 ref <-> 2 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 890 -> 892(= 登记模型 819+73)，正好 +2；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；FM-249 No black boxes。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 892、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
