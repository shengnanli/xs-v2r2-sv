# vmucp 白名单条目：LoadQueueRAW
#
# 本文件 = LoadQueueRAW 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lqraw lane，commit 5459f781 上的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 7182 / failing 0 / unverified 0 / unmatched 0(0)，
#   Not Compared = Constant reg 96 + Unread 48 → strict 判 PARTIAL(strict_unread!=0)。
#   48 个 unread 点全是 matched_nc（两侧独占 0）：
#     r:/WORK/LoadQueueRAW/detectedRollback_paddrModule_io_violationMdata_<s>_r_reg[<b>]
#       <-> i:/WORK/LoadQueueRAW/u_core/st_paddr_q_reg[<s>][<b>]
#     s ∈ {0,1}，b ∈ {0..3, 28..47}（2 × 24 位）。
#   ★为什么是对称死位★：Chisel `genPartialPAddr(RegEnable(storeIn(i).bits.paddr, storeIn(i).valid))`
#   先把 48 位 paddr 全宽打拍，再只取 [27:4] 送 LqPAddrModule 的 CAM 口；[3:0] 与 [47:28] 没有任何读者。
#   golden 与重写核是同一个 48 位寄存器、同一批死位（照抄 golden 位宽，不收窄）。
#   配对来自 fm_pins_pre.tcl 的机械钉点（与其余 4148 位同一套规则），不是为这 48 位单独人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = st_paddr_q[s][3:0] ∪ [47:28]，恰好 48 位。
#   (2) 双射：48 ref <-> 48 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 7182 -> 7230，正好 +48；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 7230、unread 归 0、unmatched 全零、constant_reg 96。

fm_target_vmucp_allow
