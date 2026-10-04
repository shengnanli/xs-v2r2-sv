# vmucp 白名单条目：ExeUnit_9（exeunits lane，执行单元外壳）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，不产 receipt；钉点 11 条全接受）----
# native SUCCEEDED / passing 2127 / failing 0 / unmatched 0 / constant_reg 30，unread 1，matched_nc：
#   Fdiv/fdiv/u_vector_float_divider_r64/fp_format_onehot_q_reg[2] —— 两侧同读 golden 的 FloatDivider 闭包内死位，
#   与 FDivSqrt 单独签核（verif/fm_target_config/FDivSqrt.tcl）记的同一点。
#
# 六条复核判据（跑后在 docs/lanes/exeunits_prereg.md 对账里逐条落数）：精确绑定（恰这 1 点）/ 双射（ref 1 <-> impl 1，
#   matched_nc）/ 真比较（vmucp 开后 passing 恰好 +1）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
