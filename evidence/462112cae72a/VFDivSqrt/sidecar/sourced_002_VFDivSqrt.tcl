# vmucp 白名单条目：VFDivSqrt（vector-fu lane）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位只在外壳本层：保持旁路寄存器 outCtrl_r_vpu_vuopIdx 存满 7 位（golden 原样），但 Mgu 的 vdIdx 与 fflags 的
#   uop 号都只取 vuopIdx[2:0]，[6:3] 两侧都没有读者 —— 与 VIDiv 外壳（verif/ut/VIDiv/fm_pins_pre.tcl 注释）同一类死位。
#   重写核里寄存器与 golden 同名（outCtrl_r_vpu_vuopIdx），预期 FM 按名配上（matched_nc，无钉点）。
#   子模块 VectorFloatDivider ×2、Mgu、VecDataSplitModule 自签核均无对称死位。
# 六条复核判据（跑后逐条落数，见 docs/lanes/vector-fu_prereg.md 对账节）：精确绑定（恰这 4 位）/ 双射 / 真比较（unread_notcompared 0，
#   passing = 模型 − constant_reg）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure。

fm_target_vmucp_allow
