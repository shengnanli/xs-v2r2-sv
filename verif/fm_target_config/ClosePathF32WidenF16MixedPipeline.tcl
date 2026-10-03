# vmucp 白名单条目：ClosePathF32WidenF16MixedPipeline（fpaddpath-sqrtblock lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据（docs/lanes/fpaddpath-sqrtblock_prereg.md §1）----
# 预期恰 2 个 matched unread 点（两侧对称死位）：
#   golden U_CS4_io_adder_op0_r_reg[23] ↔ impl u_core/cs4_op0_q_reg[23]
#     —— CS4 = {0,op0} - {0,op1} 只取结果 [22:0]，op0 的 MSB 只影响 [24:23]；
#   golden U_Lshift_io_src_r_reg[24]    ↔ impl u_core/cs_selected_q_reg[24]
#     —— 25 位左移结果只取 [23:1]，源的 MSB 左移后只会落在 >= 24 位。
#   与 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl / FAlu.tcl 记录的同两点同源。
# ---- 首跑实测（evidence/3e88b302e777/ClosePathF32WidenF16MixedPipeline，vmucp 已开）----
# native SUCCEEDED，passing 156 / failing 0 / constant_reg 3，unread 3：上面两点之外，
#   golden U_CS4_io_adder_op1_r_reg[23] ↔ impl u_core/cs4_op1_q_reg[23]（{1'b0,...} 恒 0 的减数 MSB，
#   FM 把它归 unread 而非 constant_reg —— 预登记按 constant 算了，差 1 在对账里指认）。
#   三点都是 **unmatched** unread（名字不同、无扇出签名），vmucp 单开空转 → 由
#   verif/ut/FpAddPathF32W16/fm_pins.tcl 逐对钉死（字面 3 对，fail-closed），再交 vmucp 实比。
# 六条复核判据（跑后在 prereg 对账里逐条落数）：精确绑定（恰这 3 点）/ 双射（ref 3 ↔ impl 3）/
#   真比较（钉 + vmucp 后 passing 正好 +3）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
