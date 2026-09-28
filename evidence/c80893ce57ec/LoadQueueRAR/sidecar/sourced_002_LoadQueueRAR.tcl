# vmucp 白名单条目：LoadQueueRAR
#
# 本文件 = LoadQueueRAR 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lqrar lane，commit ef64cefa 上的 diagnostic-full，vmucp 关，不出正式 receipt）----
#   native SUCCEEDED passing 3584 / failing 0 / unverified 0 / unmatched 0(0)，
#   Not Compared = Constant reg 216 + Unread 6 → strict 判 PARTIAL(strict_unread!=0)。
#   与跑前登记（docs/lanes/lqrar_prereg.md §2.3，commit 2fdc00c8）逐项一致。
#   6 个 unread 点全是 matched_nc（两侧独占 0）：
#     r:/WORK/LoadQueueRAR/release2Cycle_bits_paddr_reg[<b>]
#       <-> i:/WORK/LoadQueueRAR/u_core/release2Cycle_bits_paddr_reg[<b>]，b ∈ {0..5}。
#   ★为什么是对称死位★：Chisel `release2Cycle = RegEnable(io.release, io.release.valid)` 把 48 位 paddr
#   全宽打拍，唯一的读者是入队时的 cacheline 比较 `paddr(47, 6)`；[5:0] 没有任何读者。
#   golden 与重写核是同一个 48 位寄存器、同一批死位（照抄 golden 位宽，不收窄）。
#   配对来自 fm_pins_pre.tcl 的机械钉点（与其余 1735 位同一套规则），不是为这 6 位单独人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = release2Cycle_bits_paddr[5:0]，恰好 6 位。
#   (2) 双射：6 ref <-> 6 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 3584 -> 3590，正好 +6；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 3590、unread 归 0、unmatched 全零、constant_reg 216
#   （FreeList_3 freeSlotOH 4 bank × 54 恒零位，两侧对称：ref freeSlotOH_next_nextVec_{0..3}_r ↔
#    impl freeList/u_core/freeSlotOHReg，各 216）。

fm_target_vmucp_allow
