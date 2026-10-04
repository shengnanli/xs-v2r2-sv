# vmucp 白名单条目：VectorFloatAdder（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位全部在五条运算 lane 子树里，与各 lane 自签核时的死位逐一同组（本层只做 lane 间输入路由与结果拼接，
# 五条 lane 的全部输出都被读，不改变 lane 内任何寄存器的读者集合）：
#   U_F32_Mixed_0 / U_F32_Mixed_1：各 4 点（far FS1 低段 bit0、close CS4 被减数 / 减数 MSB、左移源 MSB）
#     —— 同 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl；
#   U_F64_Widen_0：3 点（close CS4 op0[52] / op1[52]、左移源[53]）—— 同 verif/fm_target_config/FloatAdderF64WidenPipeline.tcl；
#   U_F16_1 / U_F16_3：各 3 点（close CS4 op0[10] / op1[10]、左移源[11]）—— 同 verif/fm_target_config/FloatAdderF16Pipeline.tcl。
#   共 17 点，由 verif/ut/VectorFloatAdder/fm_pins.tcl 逐对钉死（字面 17 对，fail-closed），再交 vmucp 实比；
#   其中「恒 0 的减数 MSB」那几点预期归 constant_reg（与各 lane 自签核同）。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定（恰这 17 点）/ 双射 / 真比较（unread_notcompared 0，
#   passing = 模型 − constant_reg）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure。

fm_target_vmucp_allow
