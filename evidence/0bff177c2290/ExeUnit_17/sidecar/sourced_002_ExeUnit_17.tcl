# vmucp 白名单条目：ExeUnit_17（exublock2 lane，向量除法执行单元外壳：Vfdiv=VFDivSqrt / Vidiv=VIDiv）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，vmucp=false，不产 receipt）----
# native SUCCEEDED / passing 17019 / failing 0 / unmatched compare 0；unread 106：
#   104 matched_nc —— 与两个 FU 单独签核同一组：Vfdiv 外壳 outCtrl_r_vpu_vuopIdx[6:3] 4 位（verif/fm_target_config/VFDivSqrt.tcl）、
#     Vidiv 外壳 outCtrl_r_vpu_vuopIdx[6:3] 4 位 + vidiv 子树 96 位（verif/fm_target_config/VIDiv.tcl）；
#   2(2) unmatched unread —— Vfdiv / Vidiv 写回 pdest 锁存的 [7]：外壳给 FU 的 pdest 是 {1'h0, 7 位}、写回口只取 [6:0]，
#     [7] 恒 0 且两侧无读者，名字不同（io_out_bits_ctrl_pdest_r vs u_core/out_pdest）配不上 ——
#     scripts/gen_exeunit.py EXTRA_CHILD_PINS 按字段整组钉 8 位（fm_pins_pre.tcl），钉上后 [7] 归 constant_reg（见下）。
#
# 钉上后再跑诊断（vmucp=true，钉点 1632/1632）：native SUCCEEDED / passing 17123（= 17019 + 104）/ failing 0 / unmatched 0 /
#   unread_notcompared 0 / constant_reg 12（含两个 pdest[7]：输入恒 0，FM 判常量寄存器，不进 passing）；17123 + 12 = 模型 17135。
#
# 六条复核判据（跑后在 docs/lanes/exublock2_prereg.md 对账里逐条落数）：精确绑定（恰这 104 + 2 点）/ 双射 / 真比较（vmucp 开后
#   passing 恰好 +104、unread_notcompared 0）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar
#   script_closure，receipt 记 sha256。

fm_target_vmucp_allow
