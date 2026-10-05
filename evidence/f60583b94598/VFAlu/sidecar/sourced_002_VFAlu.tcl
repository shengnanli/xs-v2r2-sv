# vmucp 白名单条目：VFAlu（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位：
#   (a) 两个 VectorFloatAdder 子实例（vfalus_0 / vfalus_1）里各 17 点 —— 与 VectorFloatAdder 自签核同一组
#       （verif/fm_target_config/VectorFloatAdder.tcl：五条运算 lane 的 far FS1 低段 bit0、close CS4 被减数 / 减数 MSB、左移源 MSB），
#       由 verif/ut/VFAlu/fm_pins.tcl 字面钉 34 对；其中「恒 0 的减数 MSB」那几点预期归 constant_reg；
#   (b) 外壳 mgu_io_in_info_vdIdx_r[6:3]：golden 打 7 位寄存器、Mgu 只读 [2:0]，重写核同名同宽，预期 FM 按名配上（matched_nc）。
# 本外壳的其余寄存器（existMaskReg / vs1Reg / outWiden / outVlFix / allVmZero / mgu_io_in_info_eew_r / 调试信息）全部有读者。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定 / 双射 / 真比较（unread_notcompared 0，
#   passing = 模型 − constant_reg）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure。

fm_target_vmucp_allow
