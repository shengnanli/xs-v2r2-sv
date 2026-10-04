# vmucp 白名单条目：ExeUnit_10（exeunits lane，执行单元外壳）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，不产 receipt；钉点 1770 条全接受）----
# native SUCCEEDED / passing 6224 / failing 0 / unmatched 0 / constant_reg 272，unread 5，全部 matched_nc：
#   Falu 5 点 —— 与 FAlu 单独签核同一组（见 ExeUnit_8.tcl）。
#
# 六条复核判据（跑后在 docs/lanes/exeunits_prereg.md 对账里逐条落数）：精确绑定（恰这 5 点）/ 双射（ref 5 <-> impl 5，
#   matched_nc）/ 真比较（vmucp 开后 passing 恰好 +5）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
