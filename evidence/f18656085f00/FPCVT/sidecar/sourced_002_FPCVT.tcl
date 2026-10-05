# vmucp 白名单条目：FPCVT（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位：FP_INCVT 内 fcvtmodTrueExpReg[4:0]（5 位）—— 与 FP_INCVT 自签核（verif/fm_target_config/FP_INCVT.tcl，
#   首跑 evidence/75c1c255e106/FP_INCVT unread 5 = 这 5 位，两侧同名 matched_nc）及 FCVT（verif/ut/FCVT/Makefile 注释，
#   fcvt/fcvt/fpcvt/fcvtmodTrueExpReg_reg[4:0]）同一组。本层在 ref / impl 两侧都例化同一份 golden CVT64，CVT64 例化 FP_INCVT
#   （ref golden / impl 重写件），本层只多了两张组合译码表，不改变任何寄存器的读者集合。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定（恰这 5 位）/ 双射（ref ↔ impl 一一，
#   FM 按名配上，无钉点）/ 真比较（vmucp 后 passing 正好增加 unread 数）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
