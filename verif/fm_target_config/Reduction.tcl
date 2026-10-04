# vmucp 白名单条目：Reduction
#
# 本文件 = Reduction 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/backend-misc，跑前登记 docs/lanes/backend-misc_prereg.md）----
# golden 的 vdType_reg_s1 是 4 位 RegEnable(io_in_bits_vdType)，但 s1/s2 只用 [1:0]（vd 元素宽度）；
# [3:2]（vd 类型的 signed/float 位）在 golden 里零扇出。重写件照 golden 存满 4 位、同名
# （fm_pins_pre.tcl 逐位钉到 u_core/vdType_reg_s1_reg[b]），两侧同为死位。
#
# ---- 六条（standing rule）----
#   (1) 精确绑定：unread 点集合 = vdType_reg_s1_reg[3:2]，恰好 2 位。
#   (2) 双射：2 ref <-> 2 impl，由 verif/ut/Reduction/fm_pins_pre.tcl 一一钉配（fail-closed），两侧独占 0。
#   (3) 真比较：开 vmucp 后 passing 应为模型 945（寄存器 817 + 输出 128）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；child 两侧白盒，无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
