# LqExceptionBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_lqexcbuf.py（勿手改）
#
# 只消名差：golden 是按字段展平的寄存器（s2_req_<p>_<字段>、req_<字段>、s2_valid_REG_<n>…），
# 重写核是结构体数组 u_core/s2_q_reg[p]\[字段][b] 等（字段名下标带一个反斜杠，数字下标不带），
# 只在部分口存在的 isHyper / vaNeedExt 在 generate 块里：u_core/g_port[p].g_ishyper.ishyper_q_reg。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒、不 dont_verify。
# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数 != 1136 就 error。
# 进 fm.log 的输出一律 ASCII。
set ::LEB_PIN_EXPECT 1136
set ::LEB_PIN_OK 0
set ::LEB_PIN_BAD 0
proc leb_pin1 {r i} {
  if {[set_user_match $r $i]} { incr ::LEB_PIN_OK } else {
    incr ::LEB_PIN_BAD
    if {$::LEB_PIN_BAD <= 10} { puts "LEB_PIN_FAIL: $r <-> $i" }
  }
}
proc leb_pin {g i w} {
  set r "r:/WORK/LqExceptionBuffer/${g}_reg"
  set m "i:/WORK/LqExceptionBuffer/u_core/$i"
  if {$w == 1} { leb_pin1 $r $m } else {
    for {set b 0} {$b < $w} {incr b} { leb_pin1 "$r\[$b\]" "$m\[$b\]" }
  }
}
puts "LEB_PIN_BEGIN LqExceptionBuffer expect=$::LEB_PIN_EXPECT"
leb_pin s2_req_0_uop_exceptionVec_3 {s2_q_reg[0]\[uop_exceptionVec_3]} 1
leb_pin s2_req_0_uop_exceptionVec_4 {s2_q_reg[0]\[uop_exceptionVec_4]} 1
leb_pin s2_req_0_uop_exceptionVec_5 {s2_q_reg[0]\[uop_exceptionVec_5]} 1
leb_pin s2_req_0_uop_exceptionVec_13 {s2_q_reg[0]\[uop_exceptionVec_13]} 1
leb_pin s2_req_0_uop_exceptionVec_19 {s2_q_reg[0]\[uop_exceptionVec_19]} 1
leb_pin s2_req_0_uop_exceptionVec_21 {s2_q_reg[0]\[uop_exceptionVec_21]} 1
leb_pin s2_req_0_uop_uopIdx {s2_q_reg[0]\[uop_uopIdx]} 7
leb_pin s2_req_0_uop_robIdx_flag {s2_q_reg[0]\[uop_robIdx_flag]} 1
leb_pin s2_req_0_uop_robIdx_value {s2_q_reg[0]\[uop_robIdx_value]} 8
leb_pin s2_req_0_fullva {s2_q_reg[0]\[fullva]} 64
leb_pin s2_req_0_gpaddr {s2_q_reg[0]\[gpaddr]} 64
leb_pin s2_req_0_isForVSnonLeafPTE {s2_q_reg[0]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_0_isHyper {g_port[0].g_ishyper.ishyper_q_reg} 1
leb_pin s2_req_0_vaNeedExt {g_port[0].g_vaneedext.vaneedext_q_reg} 1
leb_pin s2_valid_REG {s2_valid_q_reg[0]} 1
leb_pin s2_valid_REG_1_valid {s2_redirect_q_reg[0]\[valid]} 1
leb_pin s2_valid_REG_1_bits_robIdx_flag {s2_redirect_q_reg[0]\[robIdx_flag]} 1
leb_pin s2_valid_REG_1_bits_robIdx_value {s2_redirect_q_reg[0]\[robIdx_value]} 8
leb_pin s2_valid_REG_1_bits_level {s2_redirect_q_reg[0]\[level]} 1
leb_pin s2_req_1_uop_exceptionVec_3 {s2_q_reg[1]\[uop_exceptionVec_3]} 1
leb_pin s2_req_1_uop_exceptionVec_4 {s2_q_reg[1]\[uop_exceptionVec_4]} 1
leb_pin s2_req_1_uop_exceptionVec_5 {s2_q_reg[1]\[uop_exceptionVec_5]} 1
leb_pin s2_req_1_uop_exceptionVec_13 {s2_q_reg[1]\[uop_exceptionVec_13]} 1
leb_pin s2_req_1_uop_exceptionVec_19 {s2_q_reg[1]\[uop_exceptionVec_19]} 1
leb_pin s2_req_1_uop_exceptionVec_21 {s2_q_reg[1]\[uop_exceptionVec_21]} 1
leb_pin s2_req_1_uop_uopIdx {s2_q_reg[1]\[uop_uopIdx]} 7
leb_pin s2_req_1_uop_robIdx_flag {s2_q_reg[1]\[uop_robIdx_flag]} 1
leb_pin s2_req_1_uop_robIdx_value {s2_q_reg[1]\[uop_robIdx_value]} 8
leb_pin s2_req_1_fullva {s2_q_reg[1]\[fullva]} 64
leb_pin s2_req_1_gpaddr {s2_q_reg[1]\[gpaddr]} 64
leb_pin s2_req_1_isForVSnonLeafPTE {s2_q_reg[1]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_1_isHyper {g_port[1].g_ishyper.ishyper_q_reg} 1
leb_pin s2_req_1_vaNeedExt {g_port[1].g_vaneedext.vaneedext_q_reg} 1
leb_pin s2_valid_REG_2 {s2_valid_q_reg[1]} 1
leb_pin s2_valid_REG_3_valid {s2_redirect_q_reg[1]\[valid]} 1
leb_pin s2_valid_REG_3_bits_robIdx_flag {s2_redirect_q_reg[1]\[robIdx_flag]} 1
leb_pin s2_valid_REG_3_bits_robIdx_value {s2_redirect_q_reg[1]\[robIdx_value]} 8
leb_pin s2_valid_REG_3_bits_level {s2_redirect_q_reg[1]\[level]} 1
leb_pin s2_req_2_uop_exceptionVec_3 {s2_q_reg[2]\[uop_exceptionVec_3]} 1
leb_pin s2_req_2_uop_exceptionVec_4 {s2_q_reg[2]\[uop_exceptionVec_4]} 1
leb_pin s2_req_2_uop_exceptionVec_5 {s2_q_reg[2]\[uop_exceptionVec_5]} 1
leb_pin s2_req_2_uop_exceptionVec_13 {s2_q_reg[2]\[uop_exceptionVec_13]} 1
leb_pin s2_req_2_uop_exceptionVec_19 {s2_q_reg[2]\[uop_exceptionVec_19]} 1
leb_pin s2_req_2_uop_exceptionVec_21 {s2_q_reg[2]\[uop_exceptionVec_21]} 1
leb_pin s2_req_2_uop_uopIdx {s2_q_reg[2]\[uop_uopIdx]} 7
leb_pin s2_req_2_uop_robIdx_flag {s2_q_reg[2]\[uop_robIdx_flag]} 1
leb_pin s2_req_2_uop_robIdx_value {s2_q_reg[2]\[uop_robIdx_value]} 8
leb_pin s2_req_2_fullva {s2_q_reg[2]\[fullva]} 64
leb_pin s2_req_2_gpaddr {s2_q_reg[2]\[gpaddr]} 64
leb_pin s2_req_2_isForVSnonLeafPTE {s2_q_reg[2]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_2_isHyper {g_port[2].g_ishyper.ishyper_q_reg} 1
leb_pin s2_req_2_vaNeedExt {g_port[2].g_vaneedext.vaneedext_q_reg} 1
leb_pin s2_valid_REG_4 {s2_valid_q_reg[2]} 1
leb_pin s2_valid_REG_5_valid {s2_redirect_q_reg[2]\[valid]} 1
leb_pin s2_valid_REG_5_bits_robIdx_flag {s2_redirect_q_reg[2]\[robIdx_flag]} 1
leb_pin s2_valid_REG_5_bits_robIdx_value {s2_redirect_q_reg[2]\[robIdx_value]} 8
leb_pin s2_valid_REG_5_bits_level {s2_redirect_q_reg[2]\[level]} 1
leb_pin s2_req_3_uop_exceptionVec_3 {s2_q_reg[3]\[uop_exceptionVec_3]} 1
leb_pin s2_req_3_uop_exceptionVec_4 {s2_q_reg[3]\[uop_exceptionVec_4]} 1
leb_pin s2_req_3_uop_exceptionVec_5 {s2_q_reg[3]\[uop_exceptionVec_5]} 1
leb_pin s2_req_3_uop_exceptionVec_13 {s2_q_reg[3]\[uop_exceptionVec_13]} 1
leb_pin s2_req_3_uop_exceptionVec_19 {s2_q_reg[3]\[uop_exceptionVec_19]} 1
leb_pin s2_req_3_uop_exceptionVec_21 {s2_q_reg[3]\[uop_exceptionVec_21]} 1
leb_pin s2_req_3_uop_uopIdx {s2_q_reg[3]\[uop_uopIdx]} 7
leb_pin s2_req_3_uop_robIdx_flag {s2_q_reg[3]\[uop_robIdx_flag]} 1
leb_pin s2_req_3_uop_robIdx_value {s2_q_reg[3]\[uop_robIdx_value]} 8
leb_pin s2_req_3_fullva {s2_q_reg[3]\[fullva]} 64
leb_pin s2_req_3_gpaddr {s2_q_reg[3]\[gpaddr]} 64
leb_pin s2_req_3_isForVSnonLeafPTE {s2_q_reg[3]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_3_vaNeedExt {g_port[3].g_vaneedext.vaneedext_q_reg} 1
leb_pin s2_valid_REG_6 {s2_valid_q_reg[3]} 1
leb_pin s2_valid_REG_7_valid {s2_redirect_q_reg[3]\[valid]} 1
leb_pin s2_valid_REG_7_bits_robIdx_flag {s2_redirect_q_reg[3]\[robIdx_flag]} 1
leb_pin s2_valid_REG_7_bits_robIdx_value {s2_redirect_q_reg[3]\[robIdx_value]} 8
leb_pin s2_valid_REG_7_bits_level {s2_redirect_q_reg[3]\[level]} 1
leb_pin s2_req_4_uop_exceptionVec_3 {s2_q_reg[4]\[uop_exceptionVec_3]} 1
leb_pin s2_req_4_uop_exceptionVec_4 {s2_q_reg[4]\[uop_exceptionVec_4]} 1
leb_pin s2_req_4_uop_exceptionVec_5 {s2_q_reg[4]\[uop_exceptionVec_5]} 1
leb_pin s2_req_4_uop_exceptionVec_13 {s2_q_reg[4]\[uop_exceptionVec_13]} 1
leb_pin s2_req_4_uop_exceptionVec_19 {s2_q_reg[4]\[uop_exceptionVec_19]} 1
leb_pin s2_req_4_uop_exceptionVec_21 {s2_q_reg[4]\[uop_exceptionVec_21]} 1
leb_pin s2_req_4_uop_uopIdx {s2_q_reg[4]\[uop_uopIdx]} 7
leb_pin s2_req_4_uop_robIdx_flag {s2_q_reg[4]\[uop_robIdx_flag]} 1
leb_pin s2_req_4_uop_robIdx_value {s2_q_reg[4]\[uop_robIdx_value]} 8
leb_pin s2_req_4_fullva {s2_q_reg[4]\[fullva]} 64
leb_pin s2_req_4_gpaddr {s2_q_reg[4]\[gpaddr]} 64
leb_pin s2_req_4_isForVSnonLeafPTE {s2_q_reg[4]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_4_vaNeedExt {g_port[4].g_vaneedext.vaneedext_q_reg} 1
leb_pin s2_valid_REG_8 {s2_valid_q_reg[4]} 1
leb_pin s2_valid_REG_9_valid {s2_redirect_q_reg[4]\[valid]} 1
leb_pin s2_valid_REG_9_bits_robIdx_flag {s2_redirect_q_reg[4]\[robIdx_flag]} 1
leb_pin s2_valid_REG_9_bits_robIdx_value {s2_redirect_q_reg[4]\[robIdx_value]} 8
leb_pin s2_valid_REG_9_bits_level {s2_redirect_q_reg[4]\[level]} 1
leb_pin s2_req_5_uop_exceptionVec_3 {s2_q_reg[5]\[uop_exceptionVec_3]} 1
leb_pin s2_req_5_uop_exceptionVec_4 {s2_q_reg[5]\[uop_exceptionVec_4]} 1
leb_pin s2_req_5_uop_exceptionVec_5 {s2_q_reg[5]\[uop_exceptionVec_5]} 1
leb_pin s2_req_5_uop_exceptionVec_13 {s2_q_reg[5]\[uop_exceptionVec_13]} 1
leb_pin s2_req_5_uop_exceptionVec_19 {s2_q_reg[5]\[uop_exceptionVec_19]} 1
leb_pin s2_req_5_uop_exceptionVec_21 {s2_q_reg[5]\[uop_exceptionVec_21]} 1
leb_pin s2_req_5_uop_uopIdx {s2_q_reg[5]\[uop_uopIdx]} 7
leb_pin s2_req_5_uop_robIdx_flag {s2_q_reg[5]\[uop_robIdx_flag]} 1
leb_pin s2_req_5_uop_robIdx_value {s2_q_reg[5]\[uop_robIdx_value]} 8
leb_pin s2_req_5_fullva {s2_q_reg[5]\[fullva]} 64
leb_pin s2_req_5_gpaddr {s2_q_reg[5]\[gpaddr]} 64
leb_pin s2_req_5_isForVSnonLeafPTE {s2_q_reg[5]\[isForVSnonLeafPTE]} 1
leb_pin s2_req_5_isHyper {g_port[5].g_ishyper.ishyper_q_reg} 1
leb_pin s2_valid_REG_10 {s2_valid_q_reg[5]} 1
leb_pin s2_valid_REG_11_valid {s2_redirect_q_reg[5]\[valid]} 1
leb_pin s2_valid_REG_11_bits_robIdx_flag {s2_redirect_q_reg[5]\[robIdx_flag]} 1
leb_pin s2_valid_REG_11_bits_robIdx_value {s2_redirect_q_reg[5]\[robIdx_value]} 8
leb_pin s2_valid_REG_11_bits_level {s2_redirect_q_reg[5]\[level]} 1
leb_pin req_uop_uopIdx {req_q_reg\[uop_uopIdx]} 7
leb_pin req_uop_robIdx_flag {req_q_reg\[uop_robIdx_flag]} 1
leb_pin req_uop_robIdx_value {req_q_reg\[uop_robIdx_value]} 8
leb_pin req_fullva {req_q_reg\[fullva]} 64
leb_pin req_vaNeedExt {req_q_reg\[vaNeedExt]} 1
leb_pin req_gpaddr {req_q_reg\[gpaddr]} 64
leb_pin req_isHyper {req_q_reg\[isHyper]} 1
leb_pin req_isForVSnonLeafPTE {req_q_reg\[isForVSnonLeafPTE]} 1
leb_pin req_valid {req_valid_q_reg} 1
leb_pin REG {req_valid_last_q_reg} 1
puts "LEB_PIN_END LqExceptionBuffer ok=$::LEB_PIN_OK bad=$::LEB_PIN_BAD"
if {$::LEB_PIN_BAD != 0} { error "LEB_PIN_MISS=$::LEB_PIN_BAD" }
if {$::LEB_PIN_OK != 1136} { error "LEB_PIN_COUNT=$::LEB_PIN_OK expect=1136" }
