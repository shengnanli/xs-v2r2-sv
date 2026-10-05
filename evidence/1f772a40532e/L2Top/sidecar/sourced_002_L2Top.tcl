# vmucp 白名单条目：L2Top
#
# 本文件 = L2Top 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-05，agent/l2-top，codex 0217/0222 层次化组合）----
#   canaryL（commit 798ba1e56 的 detached worktree，assembly，inner_l2cache = TL2CHICoupledL2 以 -interface_only 读入，
#   未出证、无 allow、无钉点）：native SUCCEEDED、passing 19288、failing 0、unmatched compare 0(0)、unmatched unread 0(0)、
#   constant_reg 267、unread = matched_nc 662 对：
#     inner_ptw_to_l2_buffer/nodeOut_a_q/ram_ext/Memory_reg 576 位（Queue2_TLBundleA_10 的 MC 存储模型 ram_2x117，2 项 × 288 位里
#       下游不读的字段位）、inner_buffers_4/nodeOut_a_q/ram_ext/Memory_reg 86 位（同理）。两侧读同一份已登记 MC_MEMORY_MODEL，
#       按名一一配上、两侧都无读者。
#
# ---- 六条证据（以 official receipt 为准）----
#   (1) 精确绑定：unread 集合 = 上面 662 个 matched_nc 对；unmatched_unread 两侧 0。
#   (2) 双射：662 对里 ref 互异、impl 互异；配对全部来自 FM 按名（两侧同一份 G1 模型、同一实例路径），无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为 19288 + 662 = 19950（若有位被判常量，则 passing + constant_reg 守恒 = 20217），unread 0。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒 = inner_l2cache 一个 green child
#       （-interface_only，verif/allow/L2Top.json 绑定 TL2CHICoupledL2 证书 sha256），不新增黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
