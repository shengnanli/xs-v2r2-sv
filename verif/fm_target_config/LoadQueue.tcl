# vmucp 白名单条目：LoadQueue
#
# 本文件 = LoadQueue 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lsq lane，commit 22db5f87 上的正式 strict 跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 176900 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 2431 + Unread 237 → strict 判 PARTIAL(strict_unread!=0)；
#   receipt evidence/22db5f873939/LoadQueue/（receipt.json sha256
#   950037e464811e18d695af6aba8773096a5f1f7102ce12fb75da011da5512c8f）。
#   fm_predict 模型 179568 = 176900 + 2431 + 237，差额逐位指认。
#   237 个 unread 点全是 matched_nc（两侧独占 0），按实例分布（跑前登记 docs/lanes/lsq_prereg.md §3 预测 237）：
#     loadQueueReplay 177 / loadQueueRAW 48 / loadQueueRAR 6 / uncacheBuffer 5 / exceptionBuffer 1。
#   ★都是子队列内部的对称死位，与各子队列单独签核时 vmucp 加强的是同一批点★：
#     uncacheBuffer 5（freeList.freeSlotCnt[4:0]）、exceptionBuffer 1（REG <-> req_valid_last_q）
#       与 evidence/7c7701af25a7、evidence/cce51d750b8a 的 unread 集合改前缀后逐对相等；
#     loadQueueRAR 6（release2Cycle_bits_paddr[5:0]）、loadQueueRAW 48（st_paddr_q[s][3:0]∪[47:28]）
#       与 verif/fm_target_config/LoadQueueRAR.tcl / LoadQueueRAW.tcl 记载的集合相同；
#     loadQueueReplay 177：与 evidence/71138d605681（Replay 单独签核 run #1）相比 174 对相同，
#       差 3 对：单独签核时 3 个 s2_replayMSHRId{,_1,_2}[4] 是 unread，本跑不在 unread 里；
#       本跑多出 3 个 freeList/io_canAllocate_{0,1,2}_r <-> freeList/u_core/g_pre_alloc_out.canAllocateReg[0..2]
#       —— FreeList_5 在 Replay 单独签核时是黑盒，内部死位当年量不到；两侧都是已签核件（golden FreeList_5 /
#       rtl/memblock/FreeList.sv 核），同一组 3 位、FM 按名自动配对（只差 u_core 一层）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上列 237 对，逐对来自 receipt 的 matched_unread_notcompared_pairs。
#   (2) 双射：237 ref <-> 237 impl，两侧名字各 237 个互不重复，每对在同一实例下；两侧独占 0。
#   (3) 真比较：passing 176900 -> 177137，正好 +237；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒；不设任何 per-target appvar。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 177137、unread 归 0、unmatched 全零、constant_reg 2431。

fm_target_vmucp_allow
