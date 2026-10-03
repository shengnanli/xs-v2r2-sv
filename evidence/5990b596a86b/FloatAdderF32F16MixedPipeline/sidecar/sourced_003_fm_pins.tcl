# FloatAdderF32F16MixedPipeline 钉点：far/close 子树里两侧对称死位的叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，
#  依据见 verif/fm_target_config/FloatAdderF32F16MixedPipeline.tcl）。
#
# 为什么要钉：子树 impl 读重写件，这些无读者的寄存器两侧名字不同（golden firtool 名 vs 重写核字段名），
# FM 的签名分析配不上（诊断跑：4(4) Unmatched reference(implementation) unread points）。
# 同一组点在子树自己的签核与向量那份父级里也是这样钉的（verif/ut/FpAddPathF32W16/fm_pins.tcl、
# verif/ut/FloatAdderF32WidenF16MixedPipeline/fm_pins.tcl）。
# 字面 4 对：far 的 FS1 低段和 bit0、close 的 CS4 被减数 / 减数 MSB（后者恒 0）、左移源 MSB。
# fail-closed（test_fm_pins_wellformed）：逐条数 set_user_match 返回值，钉不上就 error。
set _fm_expect 4
set _fm_n 0
if {[set_user_match r:/WORK/FloatAdderF32F16MixedPipeline/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/FloatAdderF32F16MixedPipeline/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _fm_n
}
if {[set_user_match r:/WORK/FloatAdderF32F16MixedPipeline/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/FloatAdderF32F16MixedPipeline/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _fm_n
}
if {[set_user_match r:/WORK/FloatAdderF32F16MixedPipeline/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/FloatAdderF32F16MixedPipeline/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _fm_n
}
if {[set_user_match r:/WORK/FloatAdderF32F16MixedPipeline/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/FloatAdderF32F16MixedPipeline/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _fm_n
}
puts "FADDM_PIN_END n=$_fm_n expect=$_fm_expect"
if {$_fm_n != $_fm_expect} { error "FADDM_PIN_MISS n=$_fm_n expect=$_fm_expect" }
