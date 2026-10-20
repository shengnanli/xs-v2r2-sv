# vmucp 白名单条目：TXDAT
#
# 本文件 = TXDAT 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit b1167e89 上的正式跑，vmucp 关）----
#   证据：evidence/b1167e89e520/TXDAT（signoff-strict，native SUCCEEDED）
#   passing 10196 / failing 0 / unverified 0 / unmatched 0(0)，unread 68 → strict 判 PARTIAL(strict_unread!=0)。
#   68 个 unread 点全是 matched_nc（两侧独占 0），逐点：
#     r:/WORK/TXDAT/queue/ram_ext/Memory_reg[e][b]  <-> i:/WORK/TXDAT/queue/ram_ext/Memory_reg[e][b]   e∈0..15, b∈0..3（64 个）
#     r:/WORK/TXDAT/taskR_task_off_reg[b]           <-> i:/WORK/TXDAT/u_core/taskR_task_off_reg[b]     b∈0..3（4 个）
#   ★为什么是对称死位★：TaskBundle.off 是 6 位块内偏移，TXDAT 只用 off[5:4] 当 CHI 的 CCID
#   （toCHIDATBundle: dat.ccID := task.off >> ChunkOffsetWidth）。Queue 与 taskR 按 Bundle 全宽存 off，
#   [3:0] 没有任何读者。golden 与重写件是同一个 6 位字段、同一批死位（照抄 golden 位宽，不收窄）；
#   队列 ram 两侧是同一份 golden ram_16x67（D60 inline），字段排布由 gen_l2_queues.py 逐字段校验。
#   配对是 FM 按名字自动完成的（没有任何 fm_pins / set_user_match）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = queue.ram_ext.Memory[0..15][3:0] ∪ taskR_task_off[3:0]，恰好 68 位。
#   (2) 双射：68 ref <-> 68 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 10196 -> 10264，正好 +68；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 10264、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
