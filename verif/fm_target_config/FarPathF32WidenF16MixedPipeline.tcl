# vmucp 白名单条目：FarPathF32WidenF16MixedPipeline（fpaddpath-sqrtblock lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据（docs/lanes/fpaddpath-sqrtblock_prereg.md §1）----
# 预期恰 1 个 matched unread 点：U_FS1 内低段和寄存器的第 0 位（golden 路径
#   U_FS1/io_result_r_2_reg[0]，impl 路径 u_core/U_FS1/u_core/lo_sum_q_reg[0]）。
#   FS1 = A + B + 2ulp 只在"进位"两种情形里被取用，取的是 fs1[23:1] / fs1[22:14,12:1] / fs1[24]，
#   bit0 结构上无读者；两侧是同一份 Scala 结构（golden 的 FarPathF32WidenF16MixedAdderPipeline
#   与本仓重写件逐位对应的寄存器），死位对称。父级 FloatAdderF32WidenF16MixedPipeline 与 FAlu
#   的白名单记录的是同一个点（当时两侧同读 golden）。
# 六条复核判据（跑后在 prereg 对账里逐条落数）：精确绑定（恰这 1 点）/ 双射（ref 1 ↔ impl 1
#   matched_nc）/ 真比较（vmucp 开后 passing 正好 +1）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
