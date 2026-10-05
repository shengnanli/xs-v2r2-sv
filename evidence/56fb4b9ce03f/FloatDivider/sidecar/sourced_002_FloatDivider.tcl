# vmucp 白名单条目：FloatDivider（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位只有 1 位，在除法子单元（FloatDividerR64，两侧白盒）里，与它自签核同一点
# （verif/fm_target_config/FloatDividerR64.tcl：fp_format_onehot_q_reg[2]，golden 存 3 位 one-hot 只读 [1:0]）：
#   r:/WORK/FloatDivider/u_vector_float_divider_r64/fp_format_onehot_q_reg[2]
#     <-> i:/WORK/FloatDivider/u_core/u_vector_float_divider_r64/u_core/fp_format_onehot_q_reg[2]
#   子单元自签核时 FM 按名字配上（matched_nc，无钉点）；本层不改变除法子单元任何寄存器的读者集合
#   （它的全部输出都被读：start_ready 与、finish_valid 或、结果/标志门控后或）。开方子单元（fpsqrt_r16）自签核无死位。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定（恰这 1 位）/ 双射（ref ↔ impl 一一）/
#   真比较（vmucp 后 passing 正好增加 unread 数）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
