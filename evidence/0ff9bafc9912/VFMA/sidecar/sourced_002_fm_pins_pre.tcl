# =============================================================================
# VFMA FM「匹配前」钉点 —— 两个 VectorFloatFMA 子实例（vfmas_0 / vfmas_1）内部的寄存器名差
#
# 只消名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒、不 dont_verify。
# 来源：verif/ut/VectorFloatFMA/fm_pins_pre.tcl（scripts/gen_vfma.py 生成，VectorFloatFMA 自签核用的同一套 305 条 / 1754 位），
#   逐字照搬每一条 {golden 寄存器名, 重写核寄存器路径, 位宽}，只把顶层前缀换成本层的实例路径：
#     ref  r:/WORK/VFMA/<inst>/<golden>_reg[b]   <->   impl i:/WORK/VFMA/u_core/<inst>/u_core/<重写路径>[b]
#   两个实例各一遍，期望 2 x 1754 = 3508（字面）。
# 为什么要钉：VectorFloatFMA 的 golden 是 301 个扁平寄存器，重写核是七个通道实例 + 结构化字段，FM 名字匹配
#   配不上（子模块自签核时已实测，本层不改变子模块内部的任何东西）。
# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），逐条数返回值；拒一条或总数不等于 3508 就 error。
# 本外壳自己的寄存器（valid 链 / 调试信息流水）不钉，交 FM 签名匹配。进 fm.log 的输出全 ASCII。
# =============================================================================
set ::VFMAS_PIN_EXPECT 3508
set ::VFMAS_PIN_OK 0
set ::VFMAS_PIN_BAD 0
proc vfmas_pin {inst g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/VFMA/${inst}/${g}_reg" "i:/WORK/VFMA/u_core/${inst}/u_core/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/VFMA/${inst}/${g}_reg\[$b\]" "i:/WORK/VFMA/u_core/${inst}/u_core/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::VFMAS_PIN_OK } else {
      incr ::VFMAS_PIN_BAD
      if {$::VFMAS_PIN_BAD <= 10} { puts "VFMAS_PIN_FAIL: $r <-> $m" }
    }
  }
}
proc vfmas_pin_lane {inst} {
  vfmas_pin $inst fire_reg0_last_r fire_s1_reg 1
  vfmas_pin $inst fire_reg1_last_r fire_s2_reg 1
  vfmas_pin $inst is_fp64_reg0 is_fp64_s0_q_reg 1
  vfmas_pin $inst is_fp64_reg1 is_fp64_s1_q_reg 1
  vfmas_pin $inst is_fp64_reg2 is_fp64_s2_q_reg 1
  vfmas_pin $inst is_fp32_reg0 is_fp32_s0_q_reg 1
  vfmas_pin $inst is_fp32_reg1 is_fp32_s1_q_reg 1
  vfmas_pin $inst is_fp32_reg2 is_fp32_s2_q_reg 1
  vfmas_pin $inst is_sub_f64_reg0 is_sub_f64_s0_q_reg 1
  vfmas_pin $inst rshift_guard_reg rsh_guard_s0_q_reg 4
  vfmas_pin $inst rshift_round_reg rsh_round_s0_q_reg 4
  vfmas_pin $inst rshift_sticky_reg rsh_sticky_s0_q_reg 4
  vfmas_pin $inst fp_c_rshiftValue_inv_reg c_aligned_s0_q_reg 162
  vfmas_pin $inst CSA3to2_in_b_r is_sub_csa_s0_q_reg\[2\] 1
  vfmas_pin $inst CSA3to2_in_b_r_1 is_sub_csa_s0_q_reg\[1\] 1
  vfmas_pin $inst CSA3to2_in_b_r_2 is_sub_csa_s0_q_reg\[6\] 1
  vfmas_pin $inst CSA3to2_in_b_r_3 is_sub_csa_s0_q_reg\[5\] 1
  vfmas_pin $inst CSA3to2_in_b_r_4 is_sub_csa_s0_q_reg\[4\] 1
  vfmas_pin $inst CSA3to2_in_b_r_5 is_sub_csa_s0_q_reg\[3\] 1
  vfmas_pin $inst adder_f32_0_r is_sub_adder_s0_q_reg\[1\] 1
  vfmas_pin $inst adder_f32_1_r is_sub_adder_s0_q_reg\[2\] 1
  vfmas_pin $inst adder_f16_0_r is_sub_adder_s0_q_reg\[3\] 1
  vfmas_pin $inst adder_f16_1_r is_sub_adder_s0_q_reg\[4\] 1
  vfmas_pin $inst adder_f16_2_r is_sub_adder_s0_q_reg\[5\] 1
  vfmas_pin $inst adder_f16_3_r is_sub_adder_s0_q_reg\[6\] 1
  vfmas_pin $inst adder_is_negative_reg1 adder_neg_s1_q_reg 4
  vfmas_pin $inst adder_is_negative_reg2 adder_neg_s2_q_reg 4
  vfmas_pin $inst E_greater_reg2_r exp_greater_s0_q_reg 24
  vfmas_pin $inst E_greater_reg2_r_1 exp_greater_s1_q_reg 24
  vfmas_pin $inst E_greater_reg2 exp_greater_s2_q_reg 24
  vfmas_pin $inst lshift_value_max_reg0 lshift_max_s0_q_reg 24
  vfmas_pin $inst tzd_adder_reg1 tzd_src_s1_q_reg 164
  vfmas_pin $inst lzd_adder_inv_mask_reg1 lzd_src_s1_q_reg 163
  vfmas_pin $inst lshift_mask_valid_reg mask_valid_s1_q_reg 4
  vfmas_pin $inst adder_reg1 adder_s1_q_reg 164
  vfmas_pin $inst fraction_result_no_round_reg frac_s2_q_reg 52
  vfmas_pin $inst sign_result_temp_f64_reg2_r g_lane\[0\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f64_reg2_r_1 g_lane\[0\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f64_reg2_r_2 g_lane\[0\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f64_reg2 g_lane\[0\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_0_reg2_r g_lane\[1\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_0_reg2_r_1 g_lane\[1\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_0_reg2_r_2 g_lane\[1\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_0_reg2 g_lane\[1\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_1_reg2_r g_lane\[2\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_1_reg2_r_1 g_lane\[2\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_1_reg2_r_2 g_lane\[2\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f32_1_reg2 g_lane\[2\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_0_reg2_r g_lane\[3\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_0_reg2_r_1 g_lane\[3\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_0_reg2_r_2 g_lane\[3\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_0_reg2 g_lane\[3\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_1_reg2_r g_lane\[4\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_1_reg2_r_1 g_lane\[4\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_1_reg2_r_2 g_lane\[4\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_1_reg2 g_lane\[4\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_2_reg2_r g_lane\[5\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_2_reg2_r_1 g_lane\[5\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_2_reg2_r_2 g_lane\[5\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_2_reg2 g_lane\[5\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_3_reg2_r g_lane\[6\].u_lane/sign_c_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_3_reg2_r_1 g_lane\[6\].u_lane/sign_ab_s0_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_3_reg2_r_2 g_lane\[6\].u_lane/sign_result_s1_q_reg 1
  vfmas_pin $inst sign_result_temp_f16_3_reg2 g_lane\[6\].u_lane/sign_result_s2_q_reg 1
  vfmas_pin $inst RNE_reg2_r rm_s0_q_reg\[0\] 1
  vfmas_pin $inst RNE_reg2_r_1 rm_s1_q_reg\[0\] 1
  vfmas_pin $inst RNE_reg2 rm_s2_q_reg\[0\] 1
  vfmas_pin $inst RTZ_reg2_r rm_s0_q_reg\[1\] 1
  vfmas_pin $inst RTZ_reg2_r_1 rm_s1_q_reg\[1\] 1
  vfmas_pin $inst RTZ_reg2 rm_s2_q_reg\[1\] 1
  vfmas_pin $inst RDN_reg2_r rm_s0_q_reg\[2\] 1
  vfmas_pin $inst RDN_reg2_r_1 rm_s1_q_reg\[2\] 1
  vfmas_pin $inst RDN_reg2 rm_s2_q_reg\[2\] 1
  vfmas_pin $inst RUP_reg2_r rm_s0_q_reg\[3\] 1
  vfmas_pin $inst RUP_reg2_r_1 rm_s1_q_reg\[3\] 1
  vfmas_pin $inst RUP_reg2 rm_s2_q_reg\[3\] 1
  vfmas_pin $inst RMM_reg2_r rm_s0_q_reg\[4\] 1
  vfmas_pin $inst RMM_reg2_r_1 rm_s1_q_reg\[4\] 1
  vfmas_pin $inst RMM_reg2 rm_s2_q_reg\[4\] 1
  vfmas_pin $inst sticky_f64_reg2_r g_lane\[0\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f64_reg2 g_lane\[0\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f32_0_reg2_r g_lane\[1\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f32_0_reg2 g_lane\[1\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f32_1_reg2_r g_lane\[2\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f32_1_reg2 g_lane\[2\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f16_0_reg2_r g_lane\[3\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f16_0_reg2 g_lane\[3\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f16_1_reg2_r g_lane\[4\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f16_1_reg2 g_lane\[4\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f16_2_reg2_r g_lane\[5\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f16_2_reg2 g_lane\[5\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_f16_3_reg2_r g_lane\[6\].u_lane/sticky_s1_q_reg 1
  vfmas_pin $inst sticky_f16_3_reg2 g_lane\[6\].u_lane/sticky_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f64_reg2_r g_lane\[0\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f64_reg2 g_lane\[0\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f32_0_reg2_r g_lane\[1\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f32_0_reg2 g_lane\[1\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f32_1_reg2_r g_lane\[2\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f32_1_reg2 g_lane\[2\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f16_0_reg2_r g_lane\[3\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f16_0_reg2 g_lane\[3\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f16_1_reg2_r g_lane\[4\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f16_1_reg2 g_lane\[4\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f16_2_reg2_r g_lane\[5\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f16_2_reg2 g_lane\[5\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst sticky_uf_f16_3_reg2_r g_lane\[6\].u_lane/sticky_uf_s1_q_reg 1
  vfmas_pin $inst sticky_uf_f16_3_reg2 g_lane\[6\].u_lane/sticky_uf_s2_q_reg 1
  vfmas_pin $inst round_lshift_f64_reg2 g_lane\[0\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f32_0_reg2 g_lane\[1\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f32_1_Reg2 g_lane\[2\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f16_0_reg2 g_lane\[3\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f16_1_reg2 g_lane\[4\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f16_2_reg2 g_lane\[5\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_f16_3_reg2 g_lane\[6\].u_lane/round_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f64_reg2 g_lane\[0\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f32_0_reg2 g_lane\[1\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f32_1_reg2 g_lane\[2\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f16_0_reg2 g_lane\[3\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f16_1_reg2 g_lane\[4\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f16_2_reg2 g_lane\[5\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst guard_lshift_f16_3_reg2 g_lane\[6\].u_lane/guard_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f64_reg2 g_lane\[0\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f32_0_reg2 g_lane\[1\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f32_1_reg2 g_lane\[2\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f16_0_reg2 g_lane\[3\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f16_1_reg2 g_lane\[4\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f16_2_reg2 g_lane\[5\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst round_lshift_uf_f16_3_reg2 g_lane\[6\].u_lane/round_uf_lsh_s2_q_reg 1
  vfmas_pin $inst is_fix_reg2 is_fix_s2_q_reg 4
  vfmas_pin $inst lshift_value_reg2 lshift_value_s2_q_reg 24
  vfmas_pin $inst exponent_is_min_f64 g_lane\[0\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f32_0 g_lane\[1\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f32_1 g_lane\[2\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f16_0 g_lane\[3\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f16_1 g_lane\[4\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f16_2 g_lane\[5\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst exponent_is_min_f16_3 g_lane\[6\].u_lane/exp_is_min_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f64_reg2_r g_lane\[0\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f64_reg2 g_lane\[0\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f32_0_reg2_r g_lane\[1\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f32_0_reg2 g_lane\[1\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f32_1_reg2_r g_lane\[2\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f32_1_reg2 g_lane\[2\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_0_reg2_r g_lane\[3\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_0_reg2 g_lane\[3\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_1_reg2_r g_lane\[4\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_1_reg2 g_lane\[4\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_2_reg2_r g_lane\[5\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_2_reg2 g_lane\[5\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_3_reg2_r g_lane\[6\].u_lane/result_zero_s1_q_reg 1
  vfmas_pin $inst normal_result_is_zero_f16_3_reg2 g_lane\[6\].u_lane/result_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f64_reg2_r g_lane\[0\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f64_reg2_r_1 g_lane\[0\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f64_reg2_r_2 g_lane\[0\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f32_0_reg2_r g_lane\[1\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f32_0_reg2_r_1 g_lane\[1\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f32_0_reg2_r_2 g_lane\[1\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f32_1_reg2_r g_lane\[2\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f32_1_reg2_r_1 g_lane\[2\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f32_1_reg2_r_2 g_lane\[2\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f16_0_reg2_r g_lane\[3\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f16_0_reg2_r_1 g_lane\[3\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f16_0_reg2_r_2 g_lane\[3\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f16_1_reg2_r g_lane\[4\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f16_1_reg2_r_1 g_lane\[4\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f16_1_reg2_r_2 g_lane\[4\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f16_2_reg2_r g_lane\[5\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f16_2_reg2_r_1 g_lane\[5\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f16_2_reg2_r_2 g_lane\[5\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst has_zero_f16_3_reg2_r g_lane\[6\].u_lane/has_zero_s0_q_reg 1
  vfmas_pin $inst has_zero_f16_3_reg2_r_1 g_lane\[6\].u_lane/has_zero_s1_q_reg 1
  vfmas_pin $inst has_zero_f16_3_reg2_r_2 g_lane\[6\].u_lane/has_zero_s2_q_reg 1
  vfmas_pin $inst fp_result_fp_a_or_b_is_zero_reg_r zero_result_s0_q_reg 64
  vfmas_pin $inst fp_result_fp_a_or_b_is_zero_reg_r_1 zero_result_s1_q_reg 64
  vfmas_pin $inst fp_result_fp_a_or_b_is_zero_reg zero_result_s2_q_reg 64
  vfmas_pin $inst has_nan_f64_reg2_r g_lane\[0\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f64_reg2_r_1 g_lane\[0\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f64_reg2 g_lane\[0\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f64_is_NV_reg2_r g_lane\[0\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f64_is_NV_reg2_r_1 g_lane\[0\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f64_is_NV_reg2 g_lane\[0\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f64_reg2_r g_lane\[0\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f64_reg2_r_1 g_lane\[0\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f64_reg2 g_lane\[0\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f64_is_NV_reg2_r g_lane\[0\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f64_is_NV_reg2_r_1 g_lane\[0\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f64_is_NV_reg2 g_lane\[0\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f64_result_inf_sign_reg2_r g_lane\[0\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f64_result_inf_sign_reg2_r_1 g_lane\[0\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f64_result_inf_sign_reg2 g_lane\[0\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f64_reg2_r g_lane\[0\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f64_reg2_r_1 g_lane\[0\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f64_reg2 g_lane\[0\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f32_0_reg2_r g_lane\[1\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f32_0_reg2_r_1 g_lane\[1\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f32_0_reg2 g_lane\[1\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f32_0_is_NV_reg2_r g_lane\[1\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f32_0_is_NV_reg2_r_1 g_lane\[1\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f32_0_is_NV_reg2 g_lane\[1\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_0_reg2_r g_lane\[1\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_0_reg2_r_1 g_lane\[1\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_0_reg2 g_lane\[1\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_0_is_NV_reg2_r g_lane\[1\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_0_is_NV_reg2_r_1 g_lane\[1\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_0_is_NV_reg2 g_lane\[1\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_0_result_inf_sign_reg2_r g_lane\[1\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_0_result_inf_sign_reg2_r_1 g_lane\[1\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_0_result_inf_sign_reg2 g_lane\[1\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_0_reg2_r g_lane\[1\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_0_reg2_r_1 g_lane\[1\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_0_reg2 g_lane\[1\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f32_1_reg2_r g_lane\[2\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f32_1_reg2_r_1 g_lane\[2\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f32_1_reg2 g_lane\[2\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f32_1_is_NV_reg2_r g_lane\[2\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f32_1_is_NV_reg2_r_1 g_lane\[2\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f32_1_is_NV_reg2 g_lane\[2\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_1_reg2_r g_lane\[2\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_1_reg2_r_1 g_lane\[2\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_1_reg2 g_lane\[2\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_1_is_NV_reg2_r g_lane\[2\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_1_is_NV_reg2_r_1 g_lane\[2\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_1_is_NV_reg2 g_lane\[2\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f32_1_result_inf_sign_reg2_r g_lane\[2\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f32_1_result_inf_sign_reg2_r_1 g_lane\[2\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f32_1_result_inf_sign_reg2 g_lane\[2\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_1_reg2_r g_lane\[2\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_1_reg2_r_1 g_lane\[2\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f32_1_reg2 g_lane\[2\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_0_reg2_r g_lane\[3\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_0_reg2_r_1 g_lane\[3\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_0_reg2 g_lane\[3\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_0_is_NV_reg2_r g_lane\[3\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_0_is_NV_reg2_r_1 g_lane\[3\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_0_is_NV_reg2 g_lane\[3\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_0_reg2_r g_lane\[3\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_0_reg2_r_1 g_lane\[3\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_0_reg2 g_lane\[3\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_0_is_NV_reg2_r g_lane\[3\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_0_is_NV_reg2_r_1 g_lane\[3\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_0_is_NV_reg2 g_lane\[3\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_0_result_inf_sign_reg2_r g_lane\[3\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_0_result_inf_sign_reg2_r_1 g_lane\[3\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_0_result_inf_sign_reg2 g_lane\[3\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_0_reg2_r g_lane\[3\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_0_reg2_r_1 g_lane\[3\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_0_reg2 g_lane\[3\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_1_reg2_r g_lane\[4\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_1_reg2_r_1 g_lane\[4\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_1_reg2 g_lane\[4\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_1_is_NV_reg2_r g_lane\[4\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_1_is_NV_reg2_r_1 g_lane\[4\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_1_is_NV_reg2 g_lane\[4\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_1_reg2_r g_lane\[4\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_1_reg2_r_1 g_lane\[4\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_1_reg2 g_lane\[4\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_1_is_NV_reg2_r g_lane\[4\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_1_is_NV_reg2_r_1 g_lane\[4\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_1_is_NV_reg2 g_lane\[4\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_1_result_inf_sign_reg2_r g_lane\[4\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_1_result_inf_sign_reg2_r_1 g_lane\[4\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_1_result_inf_sign_reg2 g_lane\[4\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_1_reg2_r g_lane\[4\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_1_reg2_r_1 g_lane\[4\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_1_reg2 g_lane\[4\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_2_reg2_r g_lane\[5\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_2_reg2_r_1 g_lane\[5\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_2_reg2 g_lane\[5\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_2_is_NV_reg2_r g_lane\[5\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_2_is_NV_reg2_r_1 g_lane\[5\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_2_is_NV_reg2 g_lane\[5\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_2_reg2_r g_lane\[5\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_2_reg2_r_1 g_lane\[5\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_2_reg2 g_lane\[5\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_2_is_NV_reg2_r g_lane\[5\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_2_is_NV_reg2_r_1 g_lane\[5\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_2_is_NV_reg2 g_lane\[5\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_2_result_inf_sign_reg2_r g_lane\[5\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_2_result_inf_sign_reg2_r_1 g_lane\[5\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_2_result_inf_sign_reg2 g_lane\[5\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_2_reg2_r g_lane\[5\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_2_reg2_r_1 g_lane\[5\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_2_reg2 g_lane\[5\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_3_reg2_r g_lane\[6\].u_lane/has_nan_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_3_reg2_r_1 g_lane\[6\].u_lane/has_nan_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_3_reg2 g_lane\[6\].u_lane/has_nan_s2_q_reg 1
  vfmas_pin $inst has_nan_f16_3_is_NV_reg2_r g_lane\[6\].u_lane/has_nan_nv_s0_q_reg 1
  vfmas_pin $inst has_nan_f16_3_is_NV_reg2_r_1 g_lane\[6\].u_lane/has_nan_nv_s1_q_reg 1
  vfmas_pin $inst has_nan_f16_3_is_NV_reg2 g_lane\[6\].u_lane/has_nan_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_3_reg2_r g_lane\[6\].u_lane/has_inf_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_3_reg2_r_1 g_lane\[6\].u_lane/has_inf_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_3_reg2 g_lane\[6\].u_lane/has_inf_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_3_is_NV_reg2_r g_lane\[6\].u_lane/has_inf_nv_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_3_is_NV_reg2_r_1 g_lane\[6\].u_lane/has_inf_nv_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_3_is_NV_reg2 g_lane\[6\].u_lane/has_inf_nv_s2_q_reg 1
  vfmas_pin $inst has_inf_f16_3_result_inf_sign_reg2_r g_lane\[6\].u_lane/inf_sign_s0_q_reg 1
  vfmas_pin $inst has_inf_f16_3_result_inf_sign_reg2_r_1 g_lane\[6\].u_lane/inf_sign_s1_q_reg 1
  vfmas_pin $inst has_inf_f16_3_result_inf_sign_reg2 g_lane\[6\].u_lane/inf_sign_s2_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_3_reg2_r g_lane\[6\].u_lane/ab_zero_s0_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_3_reg2_r_1 g_lane\[6\].u_lane/ab_zero_s1_q_reg 1
  vfmas_pin $inst fp_a_or_b_is_zero_f16_3_reg2 g_lane\[6\].u_lane/ab_zero_s2_q_reg 1
  vfmas_pin $inst U_CSAnto2/U_CSA4to2_io_in_a_r U_CSAnto2/u_core/level4_q_reg\[0\] 107
  vfmas_pin $inst U_CSAnto2/U_CSA4to2_io_in_b_r U_CSAnto2/u_core/level4_q_reg\[1\] 107
  vfmas_pin $inst U_CSAnto2/U_CSA4to2_io_in_c_r U_CSAnto2/u_core/level4_q_reg\[2\] 107
  vfmas_pin $inst U_CSAnto2/U_CSA4to2_io_in_d_r U_CSAnto2/u_core/level4_q_reg\[3\] 107
}
puts "VFMAS_PIN_BEGIN VFMA expect=$::VFMAS_PIN_EXPECT"
vfmas_pin_lane vfmas_0
vfmas_pin_lane vfmas_1
puts "VFMAS_PIN_END VFMA ok=$::VFMAS_PIN_OK bad=$::VFMAS_PIN_BAD"
if {$::VFMAS_PIN_BAD != 0} { error "VFMAS_PIN_MISS=$::VFMAS_PIN_BAD" }
if {$::VFMAS_PIN_OK != 3508} { error "VFMAS_PIN_COUNT=$::VFMAS_PIN_OK expect=3508" }
