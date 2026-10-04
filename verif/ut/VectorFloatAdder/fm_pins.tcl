# VectorFloatAdder 钉点：五条运算 lane 子树里两侧对称死位的叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，
#  依据见 verif/fm_target_config/VectorFloatAdder.tcl）。
#
# 为什么要钉：子树两侧白盒（ref golden / impl 重写件），这些无读者的寄存器在两侧名字不同
# （golden firtool 名 vs 重写核字段名），又无扇出签名 → FM 配不上（unmatched unread），vmucp 单开空转。
# 每条 lane 的那几对与该 lane 自己签核时的钉点逐字同一组（只把顶层前缀换成本层实例路径）：
#   U_F32_Mixed_0 / U_F32_Mixed_1 ← verif/ut/FloatAdderF32WidenF16MixedPipeline/fm_pins.tcl（各 4 对）
#   U_F64_Widen_0                 ← verif/ut/FloatAdderF64WidenPipeline/fm_pins.tcl（3 对）
#   U_F16_1 / U_F16_3             ← verif/ut/FloatAdderF16Pipeline/fm_pins.tcl（各 3 对）
# 本层只加了 lane 间的输入路由与结果拼接，每条 lane 的全部输出都被读，不改变 lane 内任何寄存器的读者集合。
# fail-closed：逐条数 set_user_match 返回值，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _vfa_expect 17
set _vfa_n 0
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_0/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_0/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_0/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_0/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_0/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_1/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_1/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_1/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F32_Mixed_1/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/VectorFloatAdder/u_core/U_F32_Mixed_1/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op0_r_reg\[52\] i:/WORK/VectorFloatAdder/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op0_q_reg\[52\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F64_Widen_0/U_close_path/U_CS4_io_adder_op1_r_reg\[52\] i:/WORK/VectorFloatAdder/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs4_op1_q_reg\[52\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F64_Widen_0/U_close_path/U_Lshift_io_src_r_reg\[53\] i:/WORK/VectorFloatAdder/u_core/U_F64_Widen_0/u_core/U_close_path/u_core/cs_selected_q_reg\[53\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_1/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VectorFloatAdder/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_1/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VectorFloatAdder/u_core/U_F16_1/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_1/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VectorFloatAdder/u_core/U_F16_1/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_3/U_close_path/U_CS4_io_adder_op0_r_reg\[10\] i:/WORK/VectorFloatAdder/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op0_q_reg\[10\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_3/U_close_path/U_CS4_io_adder_op1_r_reg\[10\] i:/WORK/VectorFloatAdder/u_core/U_F16_3/u_core/U_close_path/u_core/cs4_op1_q_reg\[10\]]} {
  incr _vfa_n
}
if {[set_user_match r:/WORK/VectorFloatAdder/U_F16_3/U_close_path/U_Lshift_io_src_r_reg\[11\] i:/WORK/VectorFloatAdder/u_core/U_F16_3/u_core/U_close_path/u_core/cs_selected_q_reg\[11\]]} {
  incr _vfa_n
}
puts "VFADD_PIN_END n=$_vfa_n expect=$_vfa_expect"
if {$_vfa_n != $_vfa_expect} { error "VFADD_PIN_MISS n=$_vfa_n expect=$_vfa_expect" }
