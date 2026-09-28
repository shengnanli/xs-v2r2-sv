# vmucp 白名单条目：RequestBuffer
#
# 本文件 = RequestBuffer 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit 4e3aa2c9 上的正式跑，vmucp 关）----
#   证据：evidence/4e3aa2c94341/RequestBuffer（signoff-strict，native SUCCEEDED，钉点 RB_PIN ok=12 bad=0）
#   passing 1592 / failing 0 / unverified 0 / unmatched 0(0)，Constant reg 9，unread 107 -> strict 判 PARTIAL。
#   107 个 unread 点全是 matched_nc（两侧独占 0），逐类：
#     r:bufferTimer_<k>_reg[b]   <-> i:u_core/bufferTimer_reg[k][b]      k in 0..3, b in 0..15   （64）
#     r:REG / REG_<n> / enable_REG[_k]（12 个 1 位）<-> i:u_core/validPrev / timerClear / histValidPrev [k]（12，钉点配对）
#     r:chosenQ/ram_reg[b]       <-> i:chosenQ/u_core/ram_reg[b]
#         b in {0,1}（表项 valid/rdy）、158..165（wayMask 位：出口强制全 1，存的那 8 位没人读）、385..404（waitMP/waitMS）（30）
#     r:issueArb/pendingMask_reg[0] <-> i:issueArb/u_core/pendingMask_reg[0]   （1：rrGrantMask[0] 恒 0 把它与掉）
#   为什么是对称死位：
#     bufferTimer 与 12 个 1 位寄存器是 Scala 的 perf 计时（enablePerf），只被 XSPerf 打印与 ifndef SYNTHESIS 的
#       assert 读；chosenQ 里这 30 位在 RequestBuffer 出口上没有对应端口；pendingMask[0] 同 FastArbiter_28 的结构死位。
#     重写与 golden 是同一批寄存器（照 golden 保留，不收窄）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 107 位。
#   (2) 双射：107 ref <-> 107 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 1592 -> 1699，正好 +107；不增即空转。（模型 1708 = 1699 + Constant reg 9。）
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1699、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
