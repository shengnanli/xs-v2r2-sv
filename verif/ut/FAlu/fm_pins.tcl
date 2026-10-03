# FAlu 钉点：FloatAdder 的 F32 / F64 两个加法器里，impl 改读重写件后两侧名字不同、FM 配不上的点的叶名配对
# （只 set_user_match，不约束 ref；只消名差，不修错配 —— 依据见 verif/fm_target_config/FAlu.tcl）。
#
# 三组，全部字面列出（fail-closed：逐条数 set_user_match 返回值，总数 != 期望就 error）：
#
# (A) 无读者的对称死位（unread），钉上后由 vmucp 实比 —— 7 对：
#     F32Adder 子树 4 对（far FS1 低段和 bit0、close CS4 被减数 / 减数 MSB、左移源 MSB；fpaddpath-sqrtblock lane 起就钉）；
#     F64Adder close path 3 对（CS4 被减数 / 减数 MSB、左移源 MSB；本 lane 起 impl 读重写件，
#     与 verif/ut/FpAddPathF64W/fm_pins.tcl 同三点）。
#
# (B) 同源双份寄存器的配对（compare point，诊断跑 16(16) unmatched compare points）—— 16 对：
#     重写件把 golden 的同源双份逐份照抄，单独签核时 FM 能按签名配上，但放进 FAlu 后这几组双份的扇出签名
#     对称、FM 分不出谁对谁。按 golden 的语义逐个钉（钉错了 FM 会判 failing，不会掩盖）：
#       F32Adder：fadd0_result1_r（f32 拼法） ↔ b_signed_f32_q、fadd0_result1_r_1（f16 拼法） ↔ b_signed_f16_q，各 5 位；
#       F64Adder close：U_Lshift_io_src_r ↔ cs_selected_q、lshift_result_head_is_one_r_1 ↔ cs_selected_chk_q（各 2 位），
#                       close_fraction_result_r ↔ frac_from_cs4_q、EA_sub_value_r ↔ exp_from_cs4_q。
set _falu_expect 23
set _falu_n 0
set _r r:/WORK/FAlu/falu
set _i i:/WORK/FAlu/u_core/falu
set _pairs [list \
  F32Adder/U_far_path/U_FS1/io_result_r_2_reg\[0\]        F32Adder/u_core/U_far_path/u_core/U_FS1/u_core/lo_sum_q_reg\[0\] \
  F32Adder/U_close_path/U_CS4_io_adder_op0_r_reg\[23\]    F32Adder/u_core/U_close_path/u_core/cs4_op0_q_reg\[23\] \
  F32Adder/U_close_path/U_CS4_io_adder_op1_r_reg\[23\]    F32Adder/u_core/U_close_path/u_core/cs4_op1_q_reg\[23\] \
  F32Adder/U_close_path/U_Lshift_io_src_r_reg\[24\]       F32Adder/u_core/U_close_path/u_core/cs_selected_q_reg\[24\] \
  F64Adder/U_close_path/U_CS4_io_adder_op0_r_reg\[52\]    F64Adder/U_close_path/u_core/cs4_op0_q_reg\[52\] \
  F64Adder/U_close_path/U_CS4_io_adder_op1_r_reg\[52\]    F64Adder/U_close_path/u_core/cs4_op1_q_reg\[52\] \
  F64Adder/U_close_path/U_Lshift_io_src_r_reg\[53\]       F64Adder/U_close_path/u_core/cs_selected_q_reg\[53\] \
  F32Adder/fadd0_result1_r_reg\[6\]                       F32Adder/u_core/b_signed_f32_q_reg\[6\] \
  F32Adder/fadd0_result1_r_reg\[7\]                       F32Adder/u_core/b_signed_f32_q_reg\[7\] \
  F32Adder/fadd0_result1_r_reg\[9\]                       F32Adder/u_core/b_signed_f32_q_reg\[9\] \
  F32Adder/fadd0_result1_r_reg\[11\]                      F32Adder/u_core/b_signed_f32_q_reg\[11\] \
  F32Adder/fadd0_result1_r_reg\[12\]                      F32Adder/u_core/b_signed_f32_q_reg\[12\] \
  F32Adder/fadd0_result1_r_1_reg\[6\]                     F32Adder/u_core/b_signed_f16_q_reg\[6\] \
  F32Adder/fadd0_result1_r_1_reg\[7\]                     F32Adder/u_core/b_signed_f16_q_reg\[7\] \
  F32Adder/fadd0_result1_r_1_reg\[9\]                     F32Adder/u_core/b_signed_f16_q_reg\[9\] \
  F32Adder/fadd0_result1_r_1_reg\[11\]                    F32Adder/u_core/b_signed_f16_q_reg\[11\] \
  F32Adder/fadd0_result1_r_1_reg\[12\]                    F32Adder/u_core/b_signed_f16_q_reg\[12\] \
  F64Adder/U_close_path/U_Lshift_io_src_r_reg\[0\]        F64Adder/U_close_path/u_core/cs_selected_q_reg\[0\] \
  F64Adder/U_close_path/U_Lshift_io_src_r_reg\[1\]        F64Adder/U_close_path/u_core/cs_selected_q_reg\[1\] \
  F64Adder/U_close_path/lshift_result_head_is_one_r_1_reg\[0\] F64Adder/U_close_path/u_core/cs_selected_chk_q_reg\[0\] \
  F64Adder/U_close_path/lshift_result_head_is_one_r_1_reg\[1\] F64Adder/U_close_path/u_core/cs_selected_chk_q_reg\[1\] \
  F64Adder/U_close_path/close_fraction_result_r_reg       F64Adder/U_close_path/u_core/frac_from_cs4_q_reg \
  F64Adder/U_close_path/EA_sub_value_r_reg                F64Adder/U_close_path/u_core/exp_from_cs4_q_reg \
]
foreach {_rp _ip} $_pairs {
  if {[set_user_match $_r/$_rp $_i/$_ip]} {
    incr _falu_n
  }
}
puts "FALU_PIN_END n=$_falu_n expect=$_falu_expect"
if {$_falu_n != $_falu_expect} { error "FALU_PIN_MISS n=$_falu_n expect=$_falu_expect" }
