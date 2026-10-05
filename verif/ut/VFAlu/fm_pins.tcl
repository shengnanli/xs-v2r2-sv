# VFAlu 钉点（匹配后）：两个 VectorFloatAdder 子实例里五条运算 lane 的两侧对称死位叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，依据见 verif/fm_target_config/VFAlu.tcl）。
# 来源：verif/ut/VectorFloatAdder/fm_pins.tcl 的同一组 17 对，逐字照搬、只把顶层前缀换成本层实例路径，两个实例各一遍 = 34 对。
# fail-closed：逐条数 set_user_match 返回值，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _vfalu_expect 34
set _vfalu_n 0
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_0/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_0/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_0/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_1/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_1/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F32_Mixed_1/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op0_r_reg\[52\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[52\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op1_r_reg\[52\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[52\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F64_Widen_0/U_close_path/U_Lshift_io_src_r_reg\[53\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs_selected_q_reg\[53\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_1/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_1/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_1/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_1/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_3/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_3/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_0/U_F16_3/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VFAlu/u_core/vfalus_0/u_core/U_F16_3/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_0/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_0/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_0/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_1/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_1/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F32_Mixed_1/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op0_r_reg\[52\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[52\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op1_r_reg\[52\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[52\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F64_Widen_0/U_close_path/U_Lshift_io_src_r_reg\[53\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs_selected_q_reg\[53\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_1/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_1/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_1/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_1/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_3/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_3/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfalu_n
}
if {[set_user_match r:/WORK/VFAlu/vfalus_1/U_F16_3/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VFAlu/u_core/vfalus_1/u_core/U_F16_3/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfalu_n
}
puts "VFALU_PIN_END n=$_vfalu_n expect=$_vfalu_expect"
if {$_vfalu_n != $_vfalu_expect} { error "VFALU_PIN_MISS n=$_vfalu_n expect=$_vfalu_expect" }
