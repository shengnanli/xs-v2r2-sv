# vmucp 白名单条目：VIMacU（kimi-vimacu lane，KIMI K3 起草 + Claude 验收）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位全部在两个 VIMac64b 实例里，与 VIMac64b 自签核（verif/fm_target_config/VIMac64b.tcl）同一组：
#   vimacs_0 / vimacs_1：uopIdxS1_reg[5:1]、uopIdxS2_reg[5:1]，每实例 10 位，共 20 位；
#   由 verif/ut/VIMacU/fm_pins_pre.tcl 字面钉配（24 条，含有读者的 [0]）。
#   本层自己的寄存器（两级 valid / 调试信息流水）全部有读者，无死位。
# 六条复核判据（跑后逐条落数，见 docs/lanes/kimi-vimacu_prereg.md）：精确绑定（恰这 20 位）/ 双射 / 真比较 /
#   全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure。

fm_target_vmucp_allow
