# vmucp 白名单条目：ClosePathF16Pipeline（fpu-parents lane，group adder16）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据（docs/lanes/fpu-parents_adder16_prereg.md §1）----
# 预期的两侧对称死位（与已签的 ClosePathF32WidenF16MixedPipeline 同源同构，那边实测 3 点）：
#   golden U_CS4_io_adder_op0_r_reg[10] ↔ impl u_core/cs4_op0_q_reg[10]
#     —— CS4 = {0,op0} - {0,op1} 只取结果 [9:0]，op0 的 MSB 只影响 [11:10]；
#   golden U_CS4_io_adder_op1_r_reg[10] ↔ impl u_core/cs4_op1_q_reg[10]
#     —— 恒 0 的减数 MSB（{1'b0, ...}），FM 可能归 unread 也可能归 constant_reg；
#   golden U_Lshift_io_src_r_reg[11]    ↔ impl u_core/cs_selected_q_reg[11]
#     —— 12 位左移结果只取 [10:1]，源的 MSB 左移后只会落在 bit11。
#   三点由 verif/ut/FpAddPathF16/fm_pins.tcl 逐对钉死（字面 3 对，fail-closed），再交 vmucp 实比。
# 六条复核判据（跑后在 prereg 对账里逐条落数）：精确绑定（恰这几点）/ 双射（ref ↔ impl 一一）/
#   真比较（钉 + vmucp 后 passing 正好增加 unread 数）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
