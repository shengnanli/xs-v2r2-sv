# FAlu 钉点：FloatAdder 的 F32 加法器（F32Adder）里 far/close 两条路径的两侧对称死位叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 实比 —— 加强不是放宽，依据见 verif/fm_target_config/FAlu.tcl）。
#
# 为什么要钉：far/close 两条路径的 impl 改读本仓重写件后（fpaddpath-sqrtblock lane），这些无读者的寄存器
# 两侧名字不同，FM 签名分析配不上（unmatched unread）。同一组点在路径自己的签核里也这样钉
# （verif/ut/FpAddPathF32W16/fm_pins.tcl，evidence/1a44b00c0b57）。F64Adder 那一点
# （U_CS4_io_adder_op0_r_reg[52]）两侧仍同读 golden、按名配上，不在这里。
# 字面 4 对；fail-closed（test_fm_pins_wellformed）：逐条数返回值，钉不上就 error。
set _falu_expect 4
set _falu_n 0
if {[set_user_match r:/WORK/FAlu/falu/F32Adder/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/FAlu/u_core/falu/F32Adder/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _falu_n
}
if {[set_user_match r:/WORK/FAlu/falu/F32Adder/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/FAlu/u_core/falu/F32Adder/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _falu_n
}
if {[set_user_match r:/WORK/FAlu/falu/F32Adder/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/FAlu/u_core/falu/F32Adder/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _falu_n
}
if {[set_user_match r:/WORK/FAlu/falu/F32Adder/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/FAlu/u_core/falu/F32Adder/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _falu_n
}
puts "FALU_PIN_END n=$_falu_n expect=$_falu_expect"
if {$_falu_n != $_falu_expect} { error "FALU_PIN_MISS n=$_falu_n expect=$_falu_expect" }
