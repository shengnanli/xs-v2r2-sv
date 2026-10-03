# vmucp 白名单条目：CountModule（fpu-parents lane，Bku 四叶子之一）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 跑前预登记的依据（docs/lanes/fpu-parents_bku_prereg.md §1）----
# 预期恰 6 个 matched unread 点：funcReg 的 [8:3]（golden r:/WORK/CountModule/funcReg_reg[3..8]，
#   impl i:/WORK/CountModule/u_core/funcReg_reg[3..8]）。CountModule 只解码 func 的 [2:0]
#   （cpop / ctz / W），Chisel 却把整个 9 位 func 拍进 funcReg，高 6 位结构上无读者；两侧是同一份
#   Scala 结构，重写件逐位照抄 9 位宽，死位对称。名字配对由 verif/ut/BkuLeaves/fm_pins_pre.tcl
#   整寄存器 9 位字面钉（fail-closed，回显 BKULEAVES_PIN_END n=9 expect=9）。
#   Bku 父级白名单（verif/fm_target_config/Bku.tcl）记录过同一组死位（countModule[3..8]，当时两侧同读 golden）。
# 六条复核判据（跑后在 prereg 对账里逐条落数）：精确绑定（恰这 6 点）/ 双射（ref 6 ↔ impl 6
#   matched_nc）/ 真比较（vmucp 开后 passing 含这 6 点，= 模型 125）/ 全零（failing / unverified /
#   unmatched 0）/ 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
