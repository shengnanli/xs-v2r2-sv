# vmucp 白名单条目：FloatDividerR64
#
# 本文件 = FloatDividerR64 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/backend-misc，跑前登记 docs/lanes/backend-misc_prereg.md）----
# lane 内非正式试跑（make fm-FloatDividerR64，vmucp 关）：native SUCCEEDED，passing 409 / failing 0 /
# unmatched 0 / constant_reg 27，unread 恰 1 点，且是 matched_nc：
#   r:/WORK/FloatDividerR64/fp_format_onehot_q_reg[2] <-> i:/WORK/FloatDividerR64/u_core/fp_format_onehot_q_reg[2]
# golden 把格式锁成 3 位 one-hot {f64,f32,f16}，但迭代后的商/余数通路只读 [1:0]（f64 是"都不是"的默认分支），
# [2] 在 golden 里零扇出；重写件照 golden 存满 3 位、同名，两侧同为死位。
#
# ---- 六条（standing rule）----
#   (1) 精确绑定：unread 点集合 = fp_format_onehot_q_reg[2]，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl，FM 按名配上（matched_nc），两侧独占 0，无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为 409 + 1 = 410（= 模型 437 − constant_reg 27）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；child 两侧白盒，无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
