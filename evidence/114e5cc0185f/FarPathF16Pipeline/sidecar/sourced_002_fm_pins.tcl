# FpAddPathF16 钉点：两侧对称死位的叶名配对（只 set_user_match，不约束 ref；配上后由 vmucp
# 让 FM 真去比这几个点 —— 加强不是放宽，白名单依据见 verif/fm_target_config/ClosePathF16Pipeline.tcl）。
#
# 为什么要钉：这些寄存器无读者（unread），FM 的签名分析配不上，名字又不同（golden 是 firtool 名，
# impl 是重写核字段名）。同构的 f32 版（verif/ut/FpAddPathF32W16/fm_pins.tcl，首跑 evidence/3e88b302e777）
# 实测过：不钉时它们全是 unmatched unread，vmucp 单开空转。本文件按 $top 分支、字面列出每一对；
# FarPathF16Pipeline 无死位（FS1 只丢结果 bit0，但 FarPathAdderF16Pipeline 不切段，两个 12 位寄存器的
# bit0 仍经进位链被读），零调用。
# fail-closed：set_user_match 对不存在的名字只返回 0、不抛异常，所以逐条数返回值，期望数量字面声明，
# 钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _fp_expect 0
set _fp_n 0
if {$top eq "ClosePathF16Pipeline"} {
  set _fp_expect 3
  # CS4 被减数 MSB：CS4 = {0,op0} - {0,op1} 只取结果 [9:0]，op0[10] 只影响 [11:10]
  if {[set_user_match r:/WORK/ClosePathF16Pipeline/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/ClosePathF16Pipeline/u_core/cs4_op0_q_reg\[10\]]} {
    incr _fp_n
  }
  # CS4 减数 MSB：恒 0（{1'b0, ...}），同样只影响 [11:10]
  if {[set_user_match r:/WORK/ClosePathF16Pipeline/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/ClosePathF16Pipeline/u_core/cs4_op1_q_reg\[10\]]} {
    incr _fp_n
  }
  # 左移源 MSB：12 位左移结果只取 [10:1]，源的 MSB 左移后只会落在 bit11
  if {[set_user_match r:/WORK/ClosePathF16Pipeline/U_Lshift_io_src_r_reg\[11\] i:/WORK/ClosePathF16Pipeline/u_core/cs_selected_q_reg\[11\]]} {
    incr _fp_n
  }
}
puts "FPADD16_PIN_END top=$top n=$_fp_n expect=$_fp_expect"
if {$_fp_n != $_fp_expect} { error "FPADD16_PIN_MISS top=$top n=$_fp_n expect=$_fp_expect" }
