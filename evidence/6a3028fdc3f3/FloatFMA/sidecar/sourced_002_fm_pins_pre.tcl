# FloatFMA FM「匹配前」钉点 —— 自动生成：scripts/gen_fma_pins.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写件（u_core / g_fmt[f].u_fmt / 压缩树 level4_q）之间的命名鸿沟；
# 钉的是 FloatFMA 子树（159 个 golden 寄存器 / 1636 位）。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。
set ::FMAPIN_OK 0
set ::FMAPIN_BAD 0
proc fmapin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/FloatFMA/${g}" "i:/WORK/FloatFMA/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/FloatFMA/${g}\[$b\]" "i:/WORK/FloatFMA/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::FMAPIN_OK } else {
      incr ::FMAPIN_BAD
      if {$::FMAPIN_BAD <= 10} { puts "FMAPIN_FAIL: $r <-> $m" }
    }
  }
}
puts "FMAPIN_BEGIN FloatFMA expect=1636"
fmapin fire_reg0_last_r_reg u_core/fire_s1_reg 1
fmapin fire_reg1_last_r_reg u_core/fire_s2_reg 1
fmapin is_fp64_reg0_reg u_core/is_fp64_s0_q_reg 1
fmapin is_fp64_reg1_reg u_core/is_fp64_s1_q_reg 1
fmapin is_fp64_reg2_reg u_core/is_fp64_s2_q_reg 1
fmapin is_fp32_reg0_reg u_core/is_fp32_s0_q_reg 1
fmapin is_fp32_reg1_reg u_core/is_fp32_s1_q_reg 1
fmapin is_fp32_reg2_reg u_core/is_fp32_s2_q_reg 1
fmapin is_sub_f64_reg0_reg u_core/g_fmt\[0\].u_fmt/is_sub_csa_q_reg 1
fmapin rshift_guard_reg_reg u_core/rsh_guard_s0_q_reg 1
fmapin rshift_round_reg_reg u_core/rsh_round_s0_q_reg 1
fmapin rshift_sticky_reg_reg u_core/rsh_sticky_s0_q_reg 1
fmapin fp_c_rshiftValue_inv_reg_reg u_core/c_aligned_s0_q_reg 162
fmapin CSA3to2_in_b_r_reg u_core/g_fmt\[1\].u_fmt/is_sub_csa_q_reg 1
fmapin CSA3to2_in_b_r_1_reg u_core/g_fmt\[2\].u_fmt/is_sub_csa_q_reg 1
fmapin adder_f32_r_reg u_core/g_fmt\[1\].u_fmt/g_is_sub_dup.is_sub_dup_q_reg 1
fmapin adder_f16_r_reg u_core/g_fmt\[2\].u_fmt/g_is_sub_dup.is_sub_dup_q_reg 1
fmapin adder_is_negative_reg1_reg u_core/adder_neg_s1_q_reg 1
fmapin adder_is_negative_reg2_reg u_core/adder_neg_s2_q_reg 1
fmapin E_greater_reg2_r_reg u_core/exp_greater_s0_q_reg 12
fmapin E_greater_reg2_r_1_reg u_core/exp_greater_s1_q_reg 12
fmapin E_greater_reg2_reg u_core/exp_greater_s2_q_reg 12
fmapin lshift_value_max_reg0_reg u_core/lshift_max_s0_q_reg 12
fmapin tzd_adder_reg1_reg u_core/tzd_src_s1_q_reg 164
fmapin lzd_adder_inv_mask_reg1_reg u_core/lzd_src_s1_q_reg 163
fmapin lshift_mask_valid_reg_reg u_core/mask_valid_s1_q_reg 1
fmapin adder_f64_reg1_reg u_core/g_fmt\[0\].u_fmt/adder_s1_q_reg 164
fmapin adder_f32_reg1_reg u_core/g_fmt\[1\].u_fmt/adder_s1_q_reg 77
fmapin adder_f16_reg1_reg u_core/g_fmt\[2\].u_fmt/adder_s1_q_reg 38
fmapin fraction_result_no_round_reg_reg u_core/frac_s2_q_reg 52
fmapin sign_result_temp_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/sign_c_s0_q_reg 1
fmapin sign_result_temp_f64_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/sign_ab_s0_q_reg 1
fmapin sign_result_temp_f64_reg2_r_2_reg u_core/g_fmt\[0\].u_fmt/sign_result_s1_q_reg 1
fmapin sign_result_temp_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/sign_result_s2_q_reg 1
fmapin sign_result_temp_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/sign_c_s0_q_reg 1
fmapin sign_result_temp_f32_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/sign_ab_s0_q_reg 1
fmapin sign_result_temp_f32_reg2_r_2_reg u_core/g_fmt\[1\].u_fmt/sign_result_s1_q_reg 1
fmapin sign_result_temp_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/sign_result_s2_q_reg 1
fmapin sign_result_temp_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/sign_c_s0_q_reg 1
fmapin sign_result_temp_f16_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/sign_ab_s0_q_reg 1
fmapin sign_result_temp_f16_reg2_r_2_reg u_core/g_fmt\[2\].u_fmt/sign_result_s1_q_reg 1
fmapin sign_result_temp_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/sign_result_s2_q_reg 1
fmapin RNE_reg2_r_reg u_core/rm_s0_q_reg\[0\] 1
fmapin RNE_reg2_r_1_reg u_core/rm_s1_q_reg\[0\] 1
fmapin RNE_reg2_reg u_core/rm_s2_q_reg\[0\] 1
fmapin RTZ_reg2_r_reg u_core/rm_s0_q_reg\[1\] 1
fmapin RTZ_reg2_r_1_reg u_core/rm_s1_q_reg\[1\] 1
fmapin RTZ_reg2_reg u_core/rm_s2_q_reg\[1\] 1
fmapin RDN_reg2_r_reg u_core/rm_s0_q_reg\[2\] 1
fmapin RDN_reg2_r_1_reg u_core/rm_s1_q_reg\[2\] 1
fmapin RDN_reg2_reg u_core/rm_s2_q_reg\[2\] 1
fmapin RUP_reg2_r_reg u_core/rm_s0_q_reg\[3\] 1
fmapin RUP_reg2_r_1_reg u_core/rm_s1_q_reg\[3\] 1
fmapin RUP_reg2_reg u_core/rm_s2_q_reg\[3\] 1
fmapin RMM_reg2_r_reg u_core/rm_s0_q_reg\[4\] 1
fmapin RMM_reg2_r_1_reg u_core/rm_s1_q_reg\[4\] 1
fmapin RMM_reg2_reg u_core/rm_s2_q_reg\[4\] 1
fmapin sticky_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/sticky_s1_q_reg 1
fmapin sticky_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/sticky_s2_q_reg 1
fmapin sticky_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/sticky_s1_q_reg 1
fmapin sticky_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/sticky_s2_q_reg 1
fmapin sticky_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/sticky_s1_q_reg 1
fmapin sticky_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/sticky_s2_q_reg 1
fmapin sticky_uf_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/sticky_uf_s1_q_reg 1
fmapin sticky_uf_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/sticky_uf_s2_q_reg 1
fmapin sticky_uf_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/sticky_uf_s1_q_reg 1
fmapin sticky_uf_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/sticky_uf_s2_q_reg 1
fmapin sticky_uf_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/sticky_uf_s1_q_reg 1
fmapin sticky_uf_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/sticky_uf_s2_q_reg 1
fmapin round_lshift_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/round_lsh_s2_q_reg 1
fmapin round_lshift_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/round_lsh_s2_q_reg 1
fmapin round_lshift_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/round_lsh_s2_q_reg 1
fmapin guard_lshift_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/guard_lsh_s2_q_reg 1
fmapin guard_lshift_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/guard_lsh_s2_q_reg 1
fmapin guard_lshift_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/guard_lsh_s2_q_reg 1
fmapin round_lshift_uf_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/round_uf_lsh_s2_q_reg 1
fmapin round_lshift_uf_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/round_uf_lsh_s2_q_reg 1
fmapin round_lshift_uf_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/round_uf_lsh_s2_q_reg 1
fmapin is_fix_reg2_reg u_core/is_fix_s2_q_reg 1
fmapin lshift_value_reg2_reg u_core/lshift_value_s2_q_reg 8
fmapin exponent_is_min_f64_reg u_core/g_fmt\[0\].u_fmt/exp_is_min_s2_q_reg 1
fmapin exponent_is_min_f32_reg u_core/g_fmt\[1\].u_fmt/exp_is_min_s2_q_reg 1
fmapin exponent_is_min_f16_reg u_core/g_fmt\[2\].u_fmt/exp_is_min_s2_q_reg 1
fmapin normal_result_is_zero_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/result_zero_s1_q_reg 1
fmapin normal_result_is_zero_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/result_zero_s2_q_reg 1
fmapin normal_result_is_zero_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/result_zero_s1_q_reg 1
fmapin normal_result_is_zero_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/result_zero_s2_q_reg 1
fmapin normal_result_is_zero_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/result_zero_s1_q_reg 1
fmapin normal_result_is_zero_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/result_zero_s2_q_reg 1
fmapin has_zero_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/has_zero_s0_q_reg 1
fmapin has_zero_f64_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/has_zero_s1_q_reg 1
fmapin has_zero_f64_reg2_r_2_reg u_core/g_fmt\[0\].u_fmt/has_zero_s2_q_reg 1
fmapin has_zero_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/has_zero_s0_q_reg 1
fmapin has_zero_f32_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/has_zero_s1_q_reg 1
fmapin has_zero_f32_reg2_r_2_reg u_core/g_fmt\[1\].u_fmt/has_zero_s2_q_reg 1
fmapin has_zero_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/has_zero_s0_q_reg 1
fmapin has_zero_f16_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/has_zero_s1_q_reg 1
fmapin has_zero_f16_reg2_r_2_reg u_core/g_fmt\[2\].u_fmt/has_zero_s2_q_reg 1
fmapin fp_result_fp_a_or_b_is_zero_reg_r_reg u_core/zero_result_s0_q_reg 64
fmapin fp_result_fp_a_or_b_is_zero_reg_r_1_reg u_core/zero_result_s1_q_reg 64
fmapin fp_result_fp_a_or_b_is_zero_reg_reg u_core/zero_result_s2_q_reg 64
fmapin has_nan_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/has_nan_s0_q_reg 1
fmapin has_nan_f64_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/has_nan_s1_q_reg 1
fmapin has_nan_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/has_nan_s2_q_reg 1
fmapin has_nan_f64_is_NV_reg2_r_reg u_core/g_fmt\[0\].u_fmt/has_nan_nv_s0_q_reg 1
fmapin has_nan_f64_is_NV_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/has_nan_nv_s1_q_reg 1
fmapin has_nan_f64_is_NV_reg2_reg u_core/g_fmt\[0\].u_fmt/has_nan_nv_s2_q_reg 1
fmapin has_inf_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/has_inf_s0_q_reg 1
fmapin has_inf_f64_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/has_inf_s1_q_reg 1
fmapin has_inf_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/has_inf_s2_q_reg 1
fmapin has_inf_f64_is_NV_reg2_r_reg u_core/g_fmt\[0\].u_fmt/has_inf_nv_s0_q_reg 1
fmapin has_inf_f64_is_NV_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/has_inf_nv_s1_q_reg 1
fmapin has_inf_f64_is_NV_reg2_reg u_core/g_fmt\[0\].u_fmt/has_inf_nv_s2_q_reg 1
fmapin has_inf_f64_result_inf_sign_reg2_r_reg u_core/g_fmt\[0\].u_fmt/inf_sign_s0_q_reg 1
fmapin has_inf_f64_result_inf_sign_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/inf_sign_s1_q_reg 1
fmapin has_inf_f64_result_inf_sign_reg2_reg u_core/g_fmt\[0\].u_fmt/inf_sign_s2_q_reg 1
fmapin fp_a_or_b_is_zero_f64_reg2_r_reg u_core/g_fmt\[0\].u_fmt/ab_zero_s0_q_reg 1
fmapin fp_a_or_b_is_zero_f64_reg2_r_1_reg u_core/g_fmt\[0\].u_fmt/ab_zero_s1_q_reg 1
fmapin fp_a_or_b_is_zero_f64_reg2_reg u_core/g_fmt\[0\].u_fmt/ab_zero_s2_q_reg 1
fmapin has_nan_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/has_nan_s0_q_reg 1
fmapin has_nan_f32_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/has_nan_s1_q_reg 1
fmapin has_nan_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/has_nan_s2_q_reg 1
fmapin has_nan_f32_is_NV_reg2_r_reg u_core/g_fmt\[1\].u_fmt/has_nan_nv_s0_q_reg 1
fmapin has_nan_f32_is_NV_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/has_nan_nv_s1_q_reg 1
fmapin has_nan_f32_is_NV_reg2_reg u_core/g_fmt\[1\].u_fmt/has_nan_nv_s2_q_reg 1
fmapin has_inf_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/has_inf_s0_q_reg 1
fmapin has_inf_f32_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/has_inf_s1_q_reg 1
fmapin has_inf_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/has_inf_s2_q_reg 1
fmapin has_inf_f32_is_NV_reg2_r_reg u_core/g_fmt\[1\].u_fmt/has_inf_nv_s0_q_reg 1
fmapin has_inf_f32_is_NV_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/has_inf_nv_s1_q_reg 1
fmapin has_inf_f32_is_NV_reg2_reg u_core/g_fmt\[1\].u_fmt/has_inf_nv_s2_q_reg 1
fmapin has_inf_f32_result_inf_sign_reg2_r_reg u_core/g_fmt\[1\].u_fmt/inf_sign_s0_q_reg 1
fmapin has_inf_f32_result_inf_sign_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/inf_sign_s1_q_reg 1
fmapin has_inf_f32_result_inf_sign_reg2_reg u_core/g_fmt\[1\].u_fmt/inf_sign_s2_q_reg 1
fmapin fp_a_or_b_is_zero_f32_reg2_r_reg u_core/g_fmt\[1\].u_fmt/ab_zero_s0_q_reg 1
fmapin fp_a_or_b_is_zero_f32_reg2_r_1_reg u_core/g_fmt\[1\].u_fmt/ab_zero_s1_q_reg 1
fmapin fp_a_or_b_is_zero_f32_reg2_reg u_core/g_fmt\[1\].u_fmt/ab_zero_s2_q_reg 1
fmapin has_nan_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/has_nan_s0_q_reg 1
fmapin has_nan_f16_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/has_nan_s1_q_reg 1
fmapin has_nan_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/has_nan_s2_q_reg 1
fmapin has_nan_f16_is_NV_reg2_r_reg u_core/g_fmt\[2\].u_fmt/has_nan_nv_s0_q_reg 1
fmapin has_nan_f16_is_NV_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/has_nan_nv_s1_q_reg 1
fmapin has_nan_f16_is_NV_reg2_reg u_core/g_fmt\[2\].u_fmt/has_nan_nv_s2_q_reg 1
fmapin has_inf_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/has_inf_s0_q_reg 1
fmapin has_inf_f16_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/has_inf_s1_q_reg 1
fmapin has_inf_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/has_inf_s2_q_reg 1
fmapin has_inf_f16_is_NV_reg2_r_reg u_core/g_fmt\[2\].u_fmt/has_inf_nv_s0_q_reg 1
fmapin has_inf_f16_is_NV_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/has_inf_nv_s1_q_reg 1
fmapin has_inf_f16_is_NV_reg2_reg u_core/g_fmt\[2\].u_fmt/has_inf_nv_s2_q_reg 1
fmapin has_inf_f16_result_inf_sign_reg2_r_reg u_core/g_fmt\[2\].u_fmt/inf_sign_s0_q_reg 1
fmapin has_inf_f16_result_inf_sign_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/inf_sign_s1_q_reg 1
fmapin has_inf_f16_result_inf_sign_reg2_reg u_core/g_fmt\[2\].u_fmt/inf_sign_s2_q_reg 1
fmapin fp_a_or_b_is_zero_f16_reg2_r_reg u_core/g_fmt\[2\].u_fmt/ab_zero_s0_q_reg 1
fmapin fp_a_or_b_is_zero_f16_reg2_r_1_reg u_core/g_fmt\[2\].u_fmt/ab_zero_s1_q_reg 1
fmapin fp_a_or_b_is_zero_f16_reg2_reg u_core/g_fmt\[2\].u_fmt/ab_zero_s2_q_reg 1
fmapin U_CSAnto2/U_CSA4to2_io_in_a_r_reg u_core/U_CSAnto2/u_core/level4_q_reg\[0\] 107
fmapin U_CSAnto2/U_CSA4to2_io_in_b_r_reg u_core/U_CSAnto2/u_core/level4_q_reg\[1\] 107
fmapin U_CSAnto2/U_CSA4to2_io_in_c_r_reg u_core/U_CSAnto2/u_core/level4_q_reg\[2\] 107
fmapin U_CSAnto2/U_CSA4to2_io_in_d_r_reg u_core/U_CSAnto2/u_core/level4_q_reg\[3\] 107
puts "FMAPIN_END FloatFMA ok=$::FMAPIN_OK bad=$::FMAPIN_BAD"
if {$::FMAPIN_BAD != 0} { error "FMAPIN_MISS=$::FMAPIN_BAD" }
if {$::FMAPIN_OK != 1636} { error "FMAPIN_COUNT=$::FMAPIN_OK expect=1636" }
