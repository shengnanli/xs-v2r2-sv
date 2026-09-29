# vmucp 白名单条目：RXSNP
#
# 本文件 = RXSNP 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit 09829392 上的正式跑，vmucp 关）----
#   证据：evidence/09829392463d/RXSNP（signoff-strict，native SUCCEEDED）
#   passing 355 / failing 0 / unverified 0 / unmatched 0(0)，unread 68 -> strict 判 PARTIAL(strict_unread!=0)。
#   与跑前登记（docs/lanes/l2slice_prereg.md 6.3：passing 355、unread 68）逐位相等。
#   68 个 unread 点全是 matched_nc（两侧独占 0），逐点：
#     r:/WORK/RXSNP/stallCnt_reg[b]                 <-> i:/WORK/RXSNP/u_core/stallCnt_reg[b]            b in 0..63（64 个）
#     r:/WORK/RXSNP/queue/ram_ext/Memory_reg[e][b]  <-> i:/WORK/RXSNP/queue/ram_ext/Memory_reg[e][b]   e in {0,1}, b in {54,55}（4 个）
#   为什么是对称死位：
#     stallCnt 是 Scala 里的死锁检测计数器，唯一读者是 ifndef SYNTHESIS 里的 assert，综合网表里只剩自身 +1 回路；
#       golden 保留了这个 64 位寄存器，重写照搬（CONVENTIONS「debug 寄存器照写」）。
#     Memory[e][55:54] = 队列里 CHISNP.addr[4:3]（ram 字里 addr 从第 51 位起）：parseAddress 把 {addr,000} 的
#       [7:6]（slice bank 位）丢掉，tag/set/off 都不取它，没有读者。两侧是同一份 golden ram_2x98（D60 inline）。
#   配对是 FM 按名字自动完成的（没有任何 fm_pins / set_user_match）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = stallCnt[63:0] 并 queue.ram_ext.Memory[0..1][55:54]，恰好 68 位。
#   (2) 双射：68 ref <-> 68 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 355 -> 423，正好 +68；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 423、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
