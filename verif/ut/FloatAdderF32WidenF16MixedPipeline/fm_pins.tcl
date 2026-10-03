# FloatAdderF32WidenF16MixedPipeline 钉点：far/close 子树里两侧对称死位的叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，
#  依据见 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl）。
#
# 为什么要钉：子树改读重写件后（fpaddpath-sqrtblock lane），这些无读者的寄存器在两侧名字不同
# （golden firtool 名 vs 重写核字段名），FM 的签名分析配不上它们（unmatched unread），vmucp 单开空转。
# 同一组点在子树自己的签核里也是这样钉的（verif/ut/FpAddPathF32W16/fm_pins.tcl，evidence/1a44b00c0b57）。
# 字面 4 对：far 的 FS1 低段和 bit0、close 的 CS4 被减数 / 减数 MSB（后者恒 0）、左移源 MSB。
# fail-closed（test_fm_pins_wellformed）：逐条数 set_user_match 返回值，钉不上就 error。
set _fa_expect 4
set _fa_n 0
if {[set_user_match r:/WORK/FloatAdderF32WidenF16MixedPipeline/U_far_path/U_FS1/io_result_r_2_reg\[0\] i:/WORK/FloatAdderF32WidenF16MixedPipeline/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]]} {
  incr _fa_n
}
if {[set_user_match r:/WORK/FloatAdderF32WidenF16MixedPipeline/U_close_path/U_CS4_io_adder_op0_r_reg\[23\] i:/WORK/FloatAdderF32WidenF16MixedPipeline/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]]} {
  incr _fa_n
}
if {[set_user_match r:/WORK/FloatAdderF32WidenF16MixedPipeline/U_close_path/U_CS4_io_adder_op1_r_reg\[23\] i:/WORK/FloatAdderF32WidenF16MixedPipeline/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]]} {
  incr _fa_n
}
if {[set_user_match r:/WORK/FloatAdderF32WidenF16MixedPipeline/U_close_path/U_Lshift_io_src_r_reg\[24\] i:/WORK/FloatAdderF32WidenF16MixedPipeline/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]]} {
  incr _fa_n
}
puts "FADDW_PIN_END n=$_fa_n expect=$_fa_expect"
if {$_fa_n != $_fa_expect} { error "FADDW_PIN_MISS n=$_fa_n expect=$_fa_expect" }
