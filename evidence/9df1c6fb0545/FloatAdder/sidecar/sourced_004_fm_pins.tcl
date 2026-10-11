# =============================================================================
# FloatAdder FM 「匹配后」钉点 —— 由集成者把两个已签子模块的钉点加实例前缀照搬（与 scripts/gen_exeunit.py CHILD_PINS 同法）：
#   F64Adder <- verif/ut/FloatAdderF64Pipeline/fm_pins.tcl; F32Adder <- verif/ut/FloatAdderF32F16MixedPipeline/fm_pins.tcl
# 只消命名差（set_user_match 一对一），不约束 ref、不改 appvar、不加黑盒；fail-closed 计数。
# =============================================================================
set ::FA_POST_OK 0
set ::FA_POST_BAD 0
proc fa_post_pin {r i {typ ""}} {
  if {$typ eq ""} { set ok [set_user_match $r $i] } else { set ok [set_user_match -type $typ $r $i] }
  if {$ok} { incr ::FA_POST_OK } else { incr ::FA_POST_BAD; puts "FA_PIN_FAIL: $r <-> $i" }
}
fa_post_pin "r:/WORK/FloatAdder/F64Adder/U_close_path/U_CS4_io_adder_op0_r_reg\[52\]" "i:/WORK/FloatAdder/F64Adder/u_core/U_close_path/u_core/cs4_op0_q_reg\[52\]"
fa_post_pin "r:/WORK/FloatAdder/F64Adder/U_close_path/U_CS4_io_adder_op1_r_reg\[52\]" "i:/WORK/FloatAdder/F64Adder/u_core/U_close_path/u_core/cs4_op1_q_reg\[52\]"
fa_post_pin "r:/WORK/FloatAdder/F64Adder/U_close_path/U_Lshift_io_src_r_reg\[53\]" "i:/WORK/FloatAdder/F64Adder/u_core/U_close_path/u_core/cs_selected_q_reg\[53\]"
fa_post_pin "r:/WORK/FloatAdder/F32Adder/U_far_path/U_FS1/io_result_r_2_reg\[0\]" "i:/WORK/FloatAdder/F32Adder/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\]"
fa_post_pin "r:/WORK/FloatAdder/F32Adder/U_close_path/U_CS4_io_adder_op0_r_reg\[23\]" "i:/WORK/FloatAdder/F32Adder/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\]"
fa_post_pin "r:/WORK/FloatAdder/F32Adder/U_close_path/U_CS4_io_adder_op1_r_reg\[23\]" "i:/WORK/FloatAdder/F32Adder/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\]"
fa_post_pin "r:/WORK/FloatAdder/F32Adder/U_close_path/U_Lshift_io_src_r_reg\[24\]" "i:/WORK/FloatAdder/F32Adder/u_core/U_close_path/u_core/cs_selected_q_reg\[24\]"
puts "FA_PIN_END post ok=$::FA_POST_OK bad=$::FA_POST_BAD expect=7"
if {$::FA_POST_BAD != 0} { error "FA_PIN_MISS=$::FA_POST_BAD" }
if {$::FA_POST_OK != 7} { error "FA_PIN_COUNT=$::FA_POST_OK expect=7" }
