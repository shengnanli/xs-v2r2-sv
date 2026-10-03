# BkuLeaves FM 匹配前钉点 —— CountModule 的 func 流水寄存器整寄存器 9 位双射
# ============================================================================
# 为什么要钉：golden CountModule 的 funcReg（Bku.scala `RegEnable(io.func, io.regEnable)`）
#   只有 [2:0] 被读（cpop / ctz / W 三个选择位），[8:3] 无读者（unread）。死位没有输出锥，
#   FM 的签名分析配不上；重写件同一寄存器在 u_core 层次下（u_core/funcReg_reg），路径不同。
#   Bku 父级的同一寄存器在 verif/ut/Bku/fm_pins_pre.tcl 已有同型先例（funcReg ↔ func_s1）。
# 本钉点做整寄存器 9 位一一对应（活位 [2:0] 一并钉死——只会更严：若可读核接错某一位，
#   FM 会失败而不是掩盖）；只消名差，不约束 ref、不 dont_verify、不加黑盒。
#   配上后 [8:3] 6 点是两侧对称的 matched unread，由 vmucp 实比（依据 verif/fm_target_config/CountModule.tcl）。
# 其余三个目标（Clmul / Misc / Hash）零调用：Clmul 的 funcReg 9 位全被读（整 9 位比较），
#   Misc / Hash 只有输出寄存器。
# fail-closed：set_user_match 对不存在的名字只返回 0、不抛异常，所以逐条数返回值，期望数字面声明。
set _bl_expect 0
set _bl_n 0
if {$top eq "CountModule"} {
  set _bl_expect 9
  for {set b 0} {$b < 9} {incr b} {
    if {[set_user_match "r:/WORK/CountModule/funcReg_reg\[$b\]" "i:/WORK/CountModule/u_core/funcReg_reg\[$b\]"]} {
      incr _bl_n
    }
  }
}
puts "BKULEAVES_PIN_END top=$top n=$_bl_n expect=$_bl_expect"
if {$_bl_n != $_bl_expect} { error "BKULEAVES_PIN_MISS top=$top n=$_bl_n expect=$_bl_expect" }
