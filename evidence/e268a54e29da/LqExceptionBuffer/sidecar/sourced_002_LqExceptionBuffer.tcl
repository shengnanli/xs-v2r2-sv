# vmucp 白名单条目：LqExceptionBuffer
#
# 本文件 = LqExceptionBuffer 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lquncache2 lane，commit cce51d75 上的正式 strict 跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 1266 / failing 0 / unmatched 0(0)，Not Compared = Unread 1
#   → strict 判 PARTIAL(strict_unread!=0)；receipt evidence/cce51d750b8a/LqExceptionBuffer/。
#   唯一的 unread 点是 matched_nc（两侧独占 0）：
#     r:/WORK/LqExceptionBuffer/REG_reg <-> i:/WORK/LqExceptionBuffer/u_core/req_valid_last_q_reg
#   ★为什么是对称死位★：Chisel `XSPerfAccumulate("exception", !RegNext(req_valid) && req_valid)`
#   里的 RegNext(req_valid)；perf 计数器在综合视图里没有输出，这个寄存器没有任何读者。
#   golden 与重写核是同一个寄存器（照抄，不删）。配对来自 fm_pins_pre.tcl 的机械钉点
#   （与其余 1135 位同一套规则，gen_lqexcbuf.py 生成），不是为这 1 位单独人工强配。
#   跑前登记 docs/lanes/lquncache2_prereg.md §3.3 预言了这一个点与 1266/1267 两个数。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {REG_reg <-> req_valid_last_q_reg}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl，matched_nc，两侧独占 0。
#   (3) 真比较：passing 1266 -> 1267，正好 +1；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1267、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
