# FloatAdderF64WidenPipeline 钉点：close 子树里两侧对称死位的叶名配对
# （只 set_user_match，不约束 ref；配上后由 vmucp 让 FM 真去比 —— 加强不是放宽，
#  依据见 verif/fm_target_config/FloatAdderF64WidenPipeline.tcl）。
#
# 为什么要钉：子树两侧白盒（ref golden / impl 重写件），这些无读者的寄存器在两侧名字不同
# （golden firtool 名 vs 重写核字段名），又无扇出签名 → FM 配不上（unmatched unread），vmucp 单开空转。
# 同一组点在子树自己的签核里也是这样钉的（verif/ut/FpAddPathF64W/fm_pins.tcl，ClosePathFloatAdderF64WidenPipeline 3 对）；
# far 子树无死位（那边零调用）。本件父级只经 close 的 io_CS1[53] 多读一位组合输出，不改变任何寄存器的读者集合。
# 字面 3 对：CS4 被减数 MSB、CS4 减数 MSB（恒 0）、左移源 MSB。
# fail-closed：逐条数 set_user_match 返回值，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _f64w_expect 3
set _f64w_n 0
if {[set_user_match r:/WORK/FloatAdderF64WidenPipeline/U_close_path/U_CS4_io_adder_op0_r_reg\[52\] i:/WORK/FloatAdderF64WidenPipeline/u_core/U_close_path/u_core/cs4_op0_q_reg\[52\]]} {
  incr _f64w_n
}
if {[set_user_match r:/WORK/FloatAdderF64WidenPipeline/U_close_path/U_CS4_io_adder_op1_r_reg\[52\] i:/WORK/FloatAdderF64WidenPipeline/u_core/U_close_path/u_core/cs4_op1_q_reg\[52\]]} {
  incr _f64w_n
}
if {[set_user_match r:/WORK/FloatAdderF64WidenPipeline/U_close_path/U_Lshift_io_src_r_reg\[53\] i:/WORK/FloatAdderF64WidenPipeline/u_core/U_close_path/u_core/cs_selected_q_reg\[53\]]} {
  incr _f64w_n
}
puts "FADD64W_PIN_END n=$_f64w_n expect=$_f64w_expect"
if {$_f64w_n != $_f64w_expect} { error "FADD64W_PIN_MISS n=$_f64w_n expect=$_f64w_expect" }
