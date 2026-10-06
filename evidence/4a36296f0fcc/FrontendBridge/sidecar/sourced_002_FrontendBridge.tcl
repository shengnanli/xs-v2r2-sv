# vmucp 白名单条目：FrontendBridge（kimi-frontendbridge lane，KIMI K3 起草 + Claude 验收）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据 ----
# 预期的两侧对称死位全部在三个子缓冲的 TileLink 队列存储里（ram_ext/Memory_reg），与各子缓冲自签核时同一组：
#   icache（ICacheBuffer）52 位 / instr_uncache（InstrUncacheBuffer）277 位 / icachectrl（ICacheCtrlBuffer）16 位，共 345 位；
#   同 verif/fm_target_config/{ICacheBuffer,InstrUncacheBuffer,ICacheCtrlBuffer}.tcl。FM 按名配上（matched_nc，无钉点）。
#   本层无寄存器（纯连线）。
# 六条复核判据见 docs/lanes/kimi-frontendbridge_prereg.md。

fm_target_vmucp_allow
