# vmucp 白名单条目：PTWFilterEntry_1
#
# 本文件 = PTWFilterEntry_1 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/ptwnewfilter lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证，commit 0f8a2684)：native SUCCEEDED passing 388 /
#   failing 0 / unmatched 全 0，unread 3 全部 matched_nc（按名配上）：
#     inflight_counter[2:0] —— 在途请求计数（发出 +1、收回 -1、flush 清 0），Chisel 里只喂
#     XSPerfAccumulate("ptw_req_cycle") 与 assert(inflight_counter <= Size)，综合口径下两者都被删，
#     golden 仍保留寄存器；重写核照抄（xs_PTWFilterEntry_core §6，与 PTWFilterEntry 同一份核）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = inflight_counter 的 3 位。
#   (2) 双射：3 ref <-> 3 impl，FM 按名配上（r:.../inflight_counter_reg[k] <-> i:.../u_core/inflight_counter_reg[k]），无人工强配。
#   (3) 真比较：开 vmucp 后 passing 应为 388 + 3 = 391 = 模型 391（regs 347 + outs 44）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；golden 0 child，无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
