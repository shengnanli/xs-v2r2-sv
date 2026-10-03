# FpAddPathF64W 钉点：f64 close path 里两侧对称死位的叶名配对（只 set_user_match，不约束 ref；
# 配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，依据见 verif/fm_target_config/ClosePathFloatAdderF64WidenPipeline.tcl）。
#
# 为什么要钉：这些寄存器无读者（unread），名字两侧不同（golden firtool 名 vs 重写核字段名），又没有扇出签名，
# FM 配不上（诊断跑：3(3) Unmatched reference(implementation) unread points）。
# 本文件按 $top 分支，字面列出每一对；FarPathAdderF64WidenPipeline 无死位，零调用。
# fail-closed（test_fm_pins_wellformed）：set_user_match 对不存在的名字只返回 0、不抛异常，
# 所以逐条数返回值，期望数量字面声明，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _f64_expect 0
set _f64_n 0
if {$top eq "ClosePathFloatAdderF64WidenPipeline"} {
  set _f64_expect 3
  # CS4 被减数 MSB：CS4 只取结果 [51:0]
  if {[set_user_match r:/WORK/ClosePathFloatAdderF64WidenPipeline/U_CS4_io_adder_op0_r_reg\[52\] i:/WORK/ClosePathFloatAdderF64WidenPipeline/u_core/cs4_op0_q_reg\[52\]]} {
    incr _f64_n
  }
  # CS4 减数 MSB：恒 0（{1'b0, ...}），同样只影响结果 [53:52]
  if {[set_user_match r:/WORK/ClosePathFloatAdderF64WidenPipeline/U_CS4_io_adder_op1_r_reg\[52\] i:/WORK/ClosePathFloatAdderF64WidenPipeline/u_core/cs4_op1_q_reg\[52\]]} {
    incr _f64_n
  }
  # 左移源 MSB：左移结果只取 [52:1]
  if {[set_user_match r:/WORK/ClosePathFloatAdderF64WidenPipeline/U_Lshift_io_src_r_reg\[53\] i:/WORK/ClosePathFloatAdderF64WidenPipeline/u_core/cs_selected_q_reg\[53\]]} {
    incr _f64_n
  }
}
puts "F64ADD_PIN_END top=$top n=$_f64_n expect=$_f64_expect"
if {$_f64_n != $_f64_expect} { error "F64ADD_PIN_MISS top=$top n=$_f64_n expect=$_f64_expect" }
