# FpAddPathF32W16 钉点：两侧对称死位的叶名配对（只 set_user_match，不约束 ref；配上后由 vmucp
# 让 FM 真去比这几个点 —— 加强不是放宽，白名单依据见 verif/fm_target_config/<top>.tcl）。
#
# 为什么要钉：这些寄存器无读者（unread），FM 的签名分析配不上，名字又不同
# （golden 是 firtool 名，impl 是重写核的字段名），首跑 evidence/3e88b302e777 里它们全是
# "Unmatched reference(implementation) unread points"，vmucp 单开空转（passing 不增）。
# 本文件按 $top 分支，字面列出每一对；AdderPipeline 无死位，零调用。
# fail-closed（test_fm_pins_wellformed）：set_user_match 对不存在的名字只返回 0、不抛异常，
# 所以逐条数返回值，期望数量字面声明，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _fp_expect 0
set _fp_n 0
if {$top eq "FarPathF32WidenF16MixedPipeline"} {
  set _fp_expect 1
  # FS1 低段和的 bit0：FS1 只取 [24:1]
  if {[set_user_match r:/WORK/FarPathF32WidenF16MixedPipeline/U_FS1/io_result_r_2_reg\[0\] i:/WORK/FarPathF32WidenF16MixedPipeline/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
    incr _fp_n
  }
}
if {$top eq "ClosePathF32WidenF16MixedPipeline"} {
  set _fp_expect 3
  # CS4 被减数 MSB：CS4 只取 [22:0]
  if {[set_user_match r:/WORK/ClosePathF32WidenF16MixedPipeline/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/ClosePathF32WidenF16MixedPipeline/u_core/cs4_op0_q_reg\[23\]]} {
    incr _fp_n
  }
  # CS4 减数 MSB：恒 0（{1'b0, ...}），同样只影响 [24:23]
  if {[set_user_match r:/WORK/ClosePathF32WidenF16MixedPipeline/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/ClosePathF32WidenF16MixedPipeline/u_core/cs4_op1_q_reg\[23\]]} {
    incr _fp_n
  }
  # 左移源 MSB：左移结果只取 [23:1]
  if {[set_user_match r:/WORK/ClosePathF32WidenF16MixedPipeline/U_Lshift_io_src_r_reg\[24\] i:/WORK/ClosePathF32WidenF16MixedPipeline/u_core/cs_selected_q_reg\[24\]]} {
    incr _fp_n
  }
}
puts "FPADD_PIN_END top=$top n=$_fp_n expect=$_fp_expect"
if {$_fp_n != $_fp_expect} { error "FPADD_PIN_MISS top=$top n=$_fp_n expect=$_fp_expect" }
