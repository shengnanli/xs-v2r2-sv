# vmucp 白名单条目：VIPU（kimi-vipu lane，KIMI 起草 + Claude 验收）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位全部在两个子单元里，与各自自签核时同一组（VIPU 只在 VIAlu 外加解码与流水 glue，
# 不改变子单元内任何寄存器的读者集合）：
#   vReduAlu（Reduction）：vdType_reg_s1[3:2] 2 位 —— 同 verif/fm_target_config/Reduction.tcl，由本目录 fm_pins_pre.tcl 字面钉配；
#   vMaskAlu（VMask）：vs1_reg_s1[127:8] 120 位 —— 同 verif/fm_target_config/VMask.tcl，FM 按名配上（matched_nc，无钉点）。
#   本层自己的寄存器（vs2Ext / opcodeS1_op / validS1 / opcodeS2_op / vs2ExtS2）全部有读者，无死位。
# 六条复核判据（跑后逐条落数，见 docs/lanes/kimi-vipu_prereg.md 对账节）：精确绑定（恰这 122 位）/ 双射 / 真比较（unread_notcompared 0，
#   passing = 模型 − constant_reg）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure。

fm_target_vmucp_allow
