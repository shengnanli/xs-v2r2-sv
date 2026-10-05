# vmucp 白名单条目：FloatAdderF64WidenPipeline（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位全部在 close 子树（ClosePathFloatAdderF64WidenPipeline，两侧白盒），与子树自己签核时的 3 点同一组
# （verif/fm_target_config/ClosePathFloatAdderF64WidenPipeline.tcl）：
#   golden U_close_path/U_CS4_io_adder_op0_r_reg[52] ↔ impl u_core/U_close_path/u_core/cs4_op0_q_reg[52]
#     —— CS4 = {0,op0} - {0,op1} 只取结果 [51:0]，op0 的 MSB 只影响 [53:52]；
#   golden U_close_path/U_CS4_io_adder_op1_r_reg[52] ↔ impl u_core/U_close_path/u_core/cs4_op1_q_reg[52]
#     —— 恒 0 的减数 MSB；
#   golden U_close_path/U_Lshift_io_src_r_reg[53]    ↔ impl u_core/U_close_path/u_core/cs_selected_q_reg[53]
#     —— 54 位左移结果只取 [52:1]，源的 MSB 左移后只会落在 bit53。
#   三点由 verif/ut/FloatAdderF64WidenPipeline/fm_pins.tcl 逐对钉死（字面 3 对，fail-closed），再交 vmucp 实比。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定（恰这几点）/ 双射（ref ↔ impl 一一）/
#   真比较（钉 + vmucp 后 passing 正好增加 unread 数）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
