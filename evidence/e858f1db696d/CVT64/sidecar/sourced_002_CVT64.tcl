# vmucp 白名单条目：CVT64（exeunits lane，标量 FPCVT 的 64 位总装）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（跑前写定，未做 FM 试跑）----
# 子模块 FP_INCVT 内 fcvtmodTrueExpReg[4:0] 是两侧对称死位：golden 与重写件都保留整个 11 位寄存器，
#   只有 [10:5] 被读（判「真指数 >= 32」），低 5 位无读者。FP_INCVT 自己签核（verif/fm_target_config/FP_INCVT.tcl）
#   与 FCVT 父级（verif/fm_target_config/FCVT.tcl）记的都是同一组 5 点；本目标在 CVT64 之下例化同一份 FP_INCVT，
#   预期 unread 恰为这 5 点（ref fpcvt/fcvtmodTrueExpReg_reg[0..4] <-> impl u_core/fpcvt/u_core/fcvtmodTrueExpReg_reg[0..4]），
#   本层（CVT64 自己的寄存器）不引入新的 unread。
# 六条复核判据（跑后在 docs/lanes/exeunits_prereg.md 对账里逐条落数）：精确绑定（恰这 5 点）/
#   双射（ref 5 <-> impl 5，matched_nc）/ 真比较（vmucp 开后 passing 计入这 5 点）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
