# vmucp 白名单条目：ExeUnit（exeunits lane，执行单元外壳）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，不产 receipt；钉点 70 条全接受）----
# native SUCCEEDED / passing 7325 / failing 0 / unmatched 0 / constant_reg 487，unread 27，全部 matched_nc：
#   Bku 20 点 —— 与 Bku 单独签核（verif/fm_target_config/Bku.tcl）同一组：countModule/funcReg[3..8]、
#     cryptoModule/funcReg[0,1,2,3,5,6,7,8]、顶层 funcReg[0,1,4,6,7,8] <-> 可读核 func_s1[同位]，两侧同为死位；
#   Mul 7 点 —— ArrayMulDataModule 部分积 / 中间级寄存器 r_2303/2304/2306（<-> pp_reg[同下标]）与
#     r_2558..2561（<-> mid_reg[251..254]），与 MulUnit 单独签核记的 7 点同一组（那时两侧同读 golden 按名配上；
#     外壳里 impl 改读重写件，由 fm_pins_pre.tcl (c) 段按下标规则钉）。r_2305 钉上后被 FM 判常量，计入 constant_reg。
#
# 六条复核判据（跑后在 docs/lanes/exeunits_prereg.md 对账里逐条落数）：精确绑定（恰这 27 点）/ 双射（ref 27 <-> impl 27，
#   matched_nc）/ 真比较（vmucp 开后 passing 恰好 +27）/ 全零（failing / unverified / unmatched 0）/
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
