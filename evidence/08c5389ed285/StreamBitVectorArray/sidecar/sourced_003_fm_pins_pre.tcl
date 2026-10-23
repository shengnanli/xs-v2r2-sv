# StreamBitVectorArray FM「匹配前」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）
#
# 只消 golden 展平寄存器名与重写核 generate 块/数组/语义名之间的命名鸿沟（规则见生成器）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。
# 进 fm.log 的输出一律 ASCII。
set ::SBVA_PIN_EXPECT 1692
set ::SBVA_PIN_OK 0
set ::SBVA_PIN_BAD 0
proc sbva_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/StreamBitVectorArray/${g}_reg" "i:/WORK/StreamBitVectorArray/u_core/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/StreamBitVectorArray/${g}_reg\[$b\]" "i:/WORK/StreamBitVectorArray/u_core/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::SBVA_PIN_OK } else {
      incr ::SBVA_PIN_BAD
      if {$::SBVA_PIN_BAD <= 10} { puts "SBVA_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "SBVA_PIN_BEGIN StreamBitVectorArray expect=$::SBVA_PIN_EXPECT"
sbva_pin array_0_tag array\[0\].tag_reg 40
sbva_pin array_0_bit_vec array\[0\].bit_vec_reg 16
sbva_pin array_0_active array\[0\].active_reg 1
sbva_pin array_0_cnt array\[0\].cnt_reg 5
sbva_pin array_1_tag array\[1\].tag_reg 40
sbva_pin array_1_bit_vec array\[1\].bit_vec_reg 16
sbva_pin array_1_active array\[1\].active_reg 1
sbva_pin array_1_cnt array\[1\].cnt_reg 5
sbva_pin array_2_tag array\[2\].tag_reg 40
sbva_pin array_2_bit_vec array\[2\].bit_vec_reg 16
sbva_pin array_2_active array\[2\].active_reg 1
sbva_pin array_2_cnt array\[2\].cnt_reg 5
sbva_pin array_3_tag array\[3\].tag_reg 40
sbva_pin array_3_bit_vec array\[3\].bit_vec_reg 16
sbva_pin array_3_active array\[3\].active_reg 1
sbva_pin array_3_cnt array\[3\].cnt_reg 5
sbva_pin array_4_tag array\[4\].tag_reg 40
sbva_pin array_4_bit_vec array\[4\].bit_vec_reg 16
sbva_pin array_4_active array\[4\].active_reg 1
sbva_pin array_4_cnt array\[4\].cnt_reg 5
sbva_pin array_5_tag array\[5\].tag_reg 40
sbva_pin array_5_bit_vec array\[5\].bit_vec_reg 16
sbva_pin array_5_active array\[5\].active_reg 1
sbva_pin array_5_cnt array\[5\].cnt_reg 5
sbva_pin array_6_tag array\[6\].tag_reg 40
sbva_pin array_6_bit_vec array\[6\].bit_vec_reg 16
sbva_pin array_6_active array\[6\].active_reg 1
sbva_pin array_6_cnt array\[6\].cnt_reg 5
sbva_pin array_7_tag array\[7\].tag_reg 40
sbva_pin array_7_bit_vec array\[7\].bit_vec_reg 16
sbva_pin array_7_active array\[7\].active_reg 1
sbva_pin array_7_cnt array\[7\].cnt_reg 5
sbva_pin array_8_tag array\[8\].tag_reg 40
sbva_pin array_8_bit_vec array\[8\].bit_vec_reg 16
sbva_pin array_8_active array\[8\].active_reg 1
sbva_pin array_8_cnt array\[8\].cnt_reg 5
sbva_pin array_9_tag array\[9\].tag_reg 40
sbva_pin array_9_bit_vec array\[9\].bit_vec_reg 16
sbva_pin array_9_active array\[9\].active_reg 1
sbva_pin array_9_cnt array\[9\].cnt_reg 5
sbva_pin array_10_tag array\[10\].tag_reg 40
sbva_pin array_10_bit_vec array\[10\].bit_vec_reg 16
sbva_pin array_10_active array\[10\].active_reg 1
sbva_pin array_10_cnt array\[10\].cnt_reg 5
sbva_pin array_11_tag array\[11\].tag_reg 40
sbva_pin array_11_bit_vec array\[11\].bit_vec_reg 16
sbva_pin array_11_active array\[11\].active_reg 1
sbva_pin array_11_cnt array\[11\].cnt_reg 5
sbva_pin array_12_tag array\[12\].tag_reg 40
sbva_pin array_12_bit_vec array\[12\].bit_vec_reg 16
sbva_pin array_12_active array\[12\].active_reg 1
sbva_pin array_12_cnt array\[12\].cnt_reg 5
sbva_pin array_13_tag array\[13\].tag_reg 40
sbva_pin array_13_bit_vec array\[13\].bit_vec_reg 16
sbva_pin array_13_active array\[13\].active_reg 1
sbva_pin array_13_cnt array\[13\].cnt_reg 5
sbva_pin array_14_tag array\[14\].tag_reg 40
sbva_pin array_14_bit_vec array\[14\].bit_vec_reg 16
sbva_pin array_14_active array\[14\].active_reg 1
sbva_pin array_14_cnt array\[14\].cnt_reg 5
sbva_pin array_15_tag array\[15\].tag_reg 40
sbva_pin array_15_bit_vec array\[15\].bit_vec_reg 16
sbva_pin array_15_active array\[15\].active_reg 1
sbva_pin array_15_cnt array\[15\].cnt_reg 5
sbva_pin valids_0 valids_reg\[0\] 1
sbva_pin valids_1 valids_reg\[1\] 1
sbva_pin valids_2 valids_reg\[2\] 1
sbva_pin valids_3 valids_reg\[3\] 1
sbva_pin valids_4 valids_reg\[4\] 1
sbva_pin valids_5 valids_reg\[5\] 1
sbva_pin valids_6 valids_reg\[6\] 1
sbva_pin valids_7 valids_reg\[7\] 1
sbva_pin valids_8 valids_reg\[8\] 1
sbva_pin valids_9 valids_reg\[9\] 1
sbva_pin valids_10 valids_reg\[10\] 1
sbva_pin valids_11 valids_reg\[11\] 1
sbva_pin valids_12 valids_reg\[12\] 1
sbva_pin valids_13 valids_reg\[13\] 1
sbva_pin valids_14 valids_reg\[14\] 1
sbva_pin valids_15 valids_reg\[15\] 1
sbva_pin state_reg u_plru/state_reg_reg 15
sbva_pin REG assert_s0_valid_d1_reg 1
sbva_pin r assert_s0_hit_d1_reg 1
sbva_pin r_1 assert_plru_way_d1_reg 4
sbva_pin s1_valid_last_REG s1_valid_last_REG_reg 1
sbva_pin s1_index s1_index_reg 4
sbva_pin s1_miss s1_miss_reg 1
sbva_pin s1_pfHit s1_pfHit_reg 1
sbva_pin s1_plus_one_index s1_plus_one_index_reg 4
sbva_pin s1_minus_one_index s1_minus_one_index_reg 4
sbva_pin s1_hit s1_hit_reg 1
sbva_pin s1_plus_one_hit_r s1_plus_one_hit_r_reg 1
sbva_pin s1_minus_one_hit_r s1_minus_one_hit_r_reg 1
sbva_pin s1_region_tag s1_region_tag_reg 40
sbva_pin s1_region_bits s1_region_bits_reg 4
sbva_pin s2_valid_last_REG s2_valid_last_REG_reg 1
sbva_pin s2_index s2_index_reg 4
sbva_pin s2_region_tag s2_region_tag_reg 40
sbva_pin s2_pf_l1_incr_vaddr s2_pf_l1_incr_vaddr_reg 50
sbva_pin s2_pf_l2_incr_vaddr s2_pf_l2_incr_vaddr_reg 50
sbva_pin s2_pf_l3_incr_vaddr s2_pf_l3_incr_vaddr_reg 50
sbva_pin s2_can_send_pf s2_can_send_pf_reg 1
sbva_pin s3_pf_l1_valid_last_REG s3_pf_l1_valid_last_REG_reg 1
sbva_pin s3_pf_l1_bits_region s3_pf_l1_bits_region_reg 40
sbva_pin s3_pf_l1_bits_bit_vec s3_pf_l1_bits_bit_vec_reg 16
sbva_pin s3_pf_l2_valid_last_REG s3_pf_l2_valid_last_REG_reg 1
sbva_pin s3_pf_l2_bits_region s3_pf_l2_bits_region_reg 40
sbva_pin s3_pf_l2_bits_bit_vec s3_pf_l2_bits_bit_vec_reg 16
sbva_pin s3_pf_l3_bits_region s3_pf_l3_bits_region_reg 40
sbva_pin s3_pf_l3_bits_bit_vec s3_pf_l3_bits_bit_vec_reg 16
sbva_pin s4_pf_l2_valid_last_REG s4_pf_l2_valid_last_REG_reg 1
sbva_pin s4_pf_l2_bits_region s4_pf_l2_bits_region_reg 40
sbva_pin s4_pf_l2_bits_bit_vec s4_pf_l2_bits_bit_vec_reg 16
sbva_pin s4_pf_l3_bits_region s4_pf_l3_bits_region_reg 40
sbva_pin s4_pf_l3_bits_bit_vec s4_pf_l3_bits_bit_vec_reg 16
sbva_pin s5_pf_l3_bits_region s5_pf_l3_bits_region_reg 40
sbva_pin s5_pf_l3_bits_bit_vec s5_pf_l3_bits_bit_vec_reg 16
sbva_pin s1_lookup_valid_last_REG s1_lookup_valid_last_REG_reg 1
sbva_pin s1_lookup_tag s1_lookup_tag_reg 40
sbva_pin s2_lookup_valid_last_REG s2_lookup_valid_last_REG_reg 1
sbva_pin s2_lookup_hit s2_lookup_hit_reg 1
sbva_pin s2_lookup_index s2_lookup_index_reg 4
sbva_pin s3_lookup_valid_last_REG s3_lookup_valid_last_REG_reg 1
sbva_pin s3_lookup_hit s3_lookup_hit_reg 1
sbva_pin s3_lookup_active s3_lookup_active_reg 1
sbva_pin last_REG array\[0\].last_REG_reg 1
sbva_pin last_REG_1 array\[1\].last_REG_reg 1
sbva_pin last_REG_2 array\[2\].last_REG_reg 1
sbva_pin last_REG_3 array\[3\].last_REG_reg 1
sbva_pin last_REG_4 array\[4\].last_REG_reg 1
sbva_pin last_REG_5 array\[5\].last_REG_reg 1
sbva_pin last_REG_6 array\[6\].last_REG_reg 1
sbva_pin last_REG_7 array\[7\].last_REG_reg 1
sbva_pin last_REG_8 array\[8\].last_REG_reg 1
sbva_pin last_REG_9 array\[9\].last_REG_reg 1
sbva_pin last_REG_10 array\[10\].last_REG_reg 1
sbva_pin last_REG_11 array\[11\].last_REG_reg 1
sbva_pin last_REG_12 array\[12\].last_REG_reg 1
sbva_pin last_REG_13 array\[13\].last_REG_reg 1
sbva_pin last_REG_14 array\[14\].last_REG_reg 1
sbva_pin last_REG_15 array\[15\].last_REG_reg 1
puts "SBVA_PIN_END StreamBitVectorArray ok=$::SBVA_PIN_OK bad=$::SBVA_PIN_BAD"
if {$::SBVA_PIN_BAD != 0} { error "SBVA_PIN_MISS=$::SBVA_PIN_BAD" }
if {$::SBVA_PIN_OK != 1692} { error "SBVA_PIN_COUNT=$::SBVA_PIN_OK expect=1692" }
