# vmucp 白名单条目：FP_INCVT（fpu-parents lane，incvt 组）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（首跑实测 evidence/75c1c255e106/FP_INCVT，vmucp 未开）----
# native SUCCEEDED，passing 462 / failing 0 / unmatched 0 / constant_reg 27，unread 5，全部 matched_nc：
#   r:/WORK/FP_INCVT/fcvtmodTrueExpReg_reg[4:0] <-> i:/WORK/FP_INCVT/u_core/fcvtmodTrueExpReg_reg[4:0]
#   fcvtmodTrueExpReg = 源指数 - 1023（fcvtmod.w.d 的真指数），golden 只读 [10:5]（判「真指数 ≥ 32」），
#   低 5 位两侧都无读者（Scala `fcvtmodTrueExpReg.head(f64.expWidth-5).orR`）。重写件照 golden 保留整个
#   11 位寄存器，死位按构造对称。父级 FCVT 的白名单（verif/fm_target_config/FCVT.tcl）记的是同一组 5 点
#   （当时两侧同读 golden FP_INCVT）。
# 六条复核判据（跑后在 docs/lanes/fpu-parents_incvt_prereg.md 对账里逐条落数）：精确绑定（恰这 5 点）/
#   双射（ref 5 ↔ impl 5，同名逐位 matched_nc）/ 真比较（vmucp 开后 passing 正好 462 -> 467，+5）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
