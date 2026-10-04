# vmucp 白名单条目：ExeUnit_8（exeunits lane，执行单元外壳）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，不产 receipt；钉点 1920 条全接受）----
# native SUCCEEDED / passing 8585 / failing 0 / unmatched 0 / constant_reg 299，unread 10，全部 matched_nc：
#   Falu 5 点 —— 与 FAlu 单独签核（verif/fm_target_config/FAlu.tcl）同一组：F32 close path CS4 op0[23] / 左移源[24]、
#     far path FS1 io_result_r_2[0]、F64 close path CS4 op0[52] / 左移源[53]；
#   Fcvt 5 点 —— FP_INCVT 的 fcvtmodTrueExpReg[4:0]（只读 [10:5]），与 FCVT / FP_INCVT / CVT64 签核记的同一组。
#
# 六条复核判据（跑后在 docs/lanes/exeunits_prereg.md 对账里逐条落数）：精确绑定（恰这 10 点）/ 双射（ref 10 <-> impl 10，
#   matched_nc）/ 真比较（vmucp 开后 passing 恰好 +10）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
