# vmucp 白名单条目：FloatAdderF32F16MixedPipeline（fpu-parents lane，group adder64）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（登记前的诊断跑，FM_MODE=diagnostic-full，不产 receipt；commit 05017d284，vmucp 关、无钉点）----
# native SUCCEEDED，passing 357 / failing 0 / constant_reg 35 / unmatched compare 0，
# 4(4) **unmatched** unread，全在 far/close 子树（impl 读重写件，名字两侧不同、无扇出签名）：
#   U_far_path/U_FS1/io_result_r_2_reg[0]      ↔ u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg[0]（拼接后丢弃的 LSB）
#   U_close_path/U_CS4_io_adder_op0_r_reg[23]  ↔ u_core/U_close_path/u_core/cs4_op0_q_reg[23]（CS4 被减数 MSB，不取）
#   U_close_path/U_CS4_io_adder_op1_r_reg[23]  ↔ u_core/U_close_path/u_core/cs4_op1_q_reg[23]（恒 0 的减数 MSB）
#   U_close_path/U_Lshift_io_src_r_reg[24]     ↔ u_core/U_close_path/u_core/cs_selected_q_reg[24]（左移源 MSB，不取）
# 与 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl（向量那份父级）同一组点、同一修法：
# 由 verif/ut/FloatAdderF32F16MixedPipeline/fm_pins.tcl 字面钉 4 对（fail-closed），再交 vmucp 实比。
# 六条复核判据（跑后在 docs/lanes/fpu-parents_adder64_prereg.md 对账里逐条落数）：精确绑定（恰这 4 点）/
#   双射（ref 4 ↔ impl 4）/ 真比较（passing 357 → 360，恒 0 那点归 constant_reg 35 → 36）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
