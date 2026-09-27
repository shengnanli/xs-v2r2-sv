# vmucp 白名单条目：IPrefetchPipe
#
# 本文件 = IPrefetchPipe 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-22, agent/icpipes 实测）----
# strict 首跑（impl commit 4be234a9，vmucp 未开）：native SUCCEEDED / passing 910
# （Port 435 + DFF 475）/ failing 0 / unverified 0 / unmatched compare points 0(0) /
# 无黑盒 / 无 dont_verify，只剩 matched-unread 96 点让 strict 判 PARTIAL。
# 这 96 点 FM 自己已经 1↔1 配上（fm_work/IPrefetchPipe/unread_points.txt 每行都是
# `matched_nc r:/WORK/IPrefetchPipe/<reg> i:/WORK/IPrefetchPipe/u_core/<reg>`，
# 非 matched_nc 项为 0），全部是两侧对称的"存了全宽、只读一截"cone-dead 位：
#   s2_req_vaddr_0/1 的 [49:14] 与 [5:0]（读点只用 [13:6] 组索引）
#   s2_req_paddr_0/1 的 [5:0]（读点只用 [47:6] 块地址与 [47:12] ptag）
#   s2_isSoftPrefetch（golden 唯一读点是 XSPerfAccumulate，perf 段在本配置下被编译掉）
# 可读核 rtl/frontend/IPrefetchPipe.sv 按 golden 存同样的寄存器，故 impl 侧对称存在
# 同一批死位；不需要 fm_pins，不约束 ref，不黑盒，不 dont_verify。
# 加强后 FM 实比这 96 对：passing 应 910 -> 1006、failing 仍 0、unread 归 0
#（实测数字以 evidence/<commit>/IPrefetchPipe/ 的 receipt 为准）。

fm_target_vmucp_allow
