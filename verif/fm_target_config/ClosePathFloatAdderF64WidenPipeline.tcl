# vmucp 白名单条目：ClosePathFloatAdderF64WidenPipeline（fpu-parents lane，group adder64）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（登记前的诊断跑，FM_MODE=diagnostic-full，不产 receipt；commit 05017d284，vmucp 关、无钉点）----
# native SUCCEEDED，passing 431 / failing 0 / unmatched compare 0，3(3) **unmatched** unread（名字不同、无扇出签名）：
#   golden U_CS4_io_adder_op0_r_reg[52] ↔ impl u_core/cs4_op0_q_reg[52]
#     —— CS4 = {0,op0} - {0,op1} 只取结果 [51:0]，op0 的 MSB 只影响 [53:52]；
#   golden U_CS4_io_adder_op1_r_reg[52] ↔ impl u_core/cs4_op1_q_reg[52]
#     —— {1'b0, ...} 恒 0 的减数 MSB，同上只影响 [53:52]；
#   golden U_Lshift_io_src_r_reg[53]    ↔ impl u_core/cs_selected_q_reg[53]
#     —— 54 位左移结果只取 [52:1]，源的 MSB 左移后只会落在 bit 53。
#   与 f32 那份（ClosePathF32WidenF16MixedPipeline.tcl）同构的同三点。
# 由 verif/ut/FpAddPathF64W/fm_pins.tcl 逐对钉死（字面 3 对，fail-closed），再交 vmucp 实比。
# 六条复核判据（跑后在 docs/lanes/fpu-parents_adder64_prereg.md 对账里逐条落数）：精确绑定（恰这 3 点）/
#   双射（ref 3 ↔ impl 3）/ 真比较（钉 + vmucp 后 passing 431 → 433，恒 0 的减数 MSB 归 constant_reg）/
#   全零（failing / unverified / unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 /
#   本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
