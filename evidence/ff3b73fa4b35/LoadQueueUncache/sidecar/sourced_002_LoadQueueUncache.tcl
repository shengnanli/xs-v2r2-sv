# vmucp 白名单条目：LoadQueueUncache
#
# 本文件 = LoadQueueUncache 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lquncache2 lane，commit 7c7701af 上的正式 strict 跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 43316 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 1616 + Unread 5 → strict 判 PARTIAL(strict_unread!=0)；
#   receipt evidence/7c7701af25a7/LoadQueueUncache/。
#   5 个 unread 点全是 matched_nc（两侧独占 0）：
#     r:/WORK/LoadQueueUncache/freeList/freeSlotCnt_reg[b]
#       <-> i:/WORK/LoadQueueUncache/u_core/freeList/u_core/freeSlotCnt_reg[b]，b = 0..4。
#   ★为什么是对称死位★：FreeList 的空闲计数只驱动 io_validCount / io_empty；LoadQueueUncache
#   把这两个输出只接到 perf（QueuePerf，golden 里是 _probe 线），综合视图没有读者。
#   两侧都是已签核的 FreeList_6 家族件（golden 同名件 vs rtl/memblock/FreeList.sv 核），
#   同一个 5 位寄存器、同一批死位；配对是 FM 按名自动配对（只差 u_core 一层），不是人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = freeList.freeSlotCnt[4:0]，恰好 5 位。
#   (2) 双射：5 ref <-> 5 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 43316 -> 43321，正好 +5；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 43321、unread 归 0、unmatched 全零、constant_reg 1616。

fm_target_vmucp_allow
