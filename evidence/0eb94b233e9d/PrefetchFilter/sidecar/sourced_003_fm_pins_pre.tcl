# PrefetchFilter FM「匹配前」钉点 —— 自动生成：scripts/gen_mmuleaf.py（勿手改）
#
# 只消 golden 展平寄存器名与重写核 generate 块/数组/语义名之间的命名鸿沟（规则见生成器）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= golden 顶层寄存器位数）就 error（safe interp 里不用 exit）。
# 进 fm.log 的输出一律 ASCII。
set ::PFF_PIN_EXPECT 1792
set ::PFF_PIN_OK 0
set ::PFF_PIN_BAD 0
proc pff_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PrefetchFilter/${g}_reg" "i:/WORK/PrefetchFilter/u_core/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PrefetchFilter/${g}_reg\[$b\]" "i:/WORK/PrefetchFilter/u_core/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::PFF_PIN_OK } else {
      incr ::PFF_PIN_BAD
      if {$::PFF_PIN_BAD <= 10} { puts "PFF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "PFF_PIN_BEGIN PrefetchFilter expect=$::PFF_PIN_EXPECT"
pff_pin s3_tlb_fire_vec_r_r_15 s3_tlb_fire_vec_reg\[15\] 1
pff_pin s3_tlb_fire_vec_r_r_14 s3_tlb_fire_vec_reg\[14\] 1
pff_pin s3_tlb_fire_vec_r_r_13 s3_tlb_fire_vec_reg\[13\] 1
pff_pin s3_tlb_fire_vec_r_r_12 s3_tlb_fire_vec_reg\[12\] 1
pff_pin s3_tlb_fire_vec_r_r_11 s3_tlb_fire_vec_reg\[11\] 1
pff_pin s3_tlb_fire_vec_r_r_10 s3_tlb_fire_vec_reg\[10\] 1
pff_pin s3_tlb_fire_vec_r_r_9 s3_tlb_fire_vec_reg\[9\] 1
pff_pin s3_tlb_fire_vec_r_r_8 s3_tlb_fire_vec_reg\[8\] 1
pff_pin s3_tlb_fire_vec_r_r_7 s3_tlb_fire_vec_reg\[7\] 1
pff_pin s3_tlb_fire_vec_r_r_6 s3_tlb_fire_vec_reg\[6\] 1
pff_pin s3_tlb_fire_vec_r_r_5 s3_tlb_fire_vec_reg\[5\] 1
pff_pin s3_tlb_fire_vec_r_r_4 s3_tlb_fire_vec_reg\[4\] 1
pff_pin s3_tlb_fire_vec_r_r_3 s3_tlb_fire_vec_reg\[3\] 1
pff_pin s3_tlb_fire_vec_r_r_2 s3_tlb_fire_vec_reg\[2\] 1
pff_pin s3_tlb_fire_vec_r_r_1 s3_tlb_fire_vec_reg\[1\] 1
pff_pin s3_tlb_fire_vec_r_r_0 s3_tlb_fire_vec_reg\[0\] 1
pff_pin s2_tlb_fire_vec_r_r_15 s2_tlb_fire_vec_reg\[15\] 1
pff_pin s2_tlb_fire_vec_r_r_14 s2_tlb_fire_vec_reg\[14\] 1
pff_pin s2_tlb_fire_vec_r_r_13 s2_tlb_fire_vec_reg\[13\] 1
pff_pin s2_tlb_fire_vec_r_r_12 s2_tlb_fire_vec_reg\[12\] 1
pff_pin s2_tlb_fire_vec_r_r_11 s2_tlb_fire_vec_reg\[11\] 1
pff_pin s2_tlb_fire_vec_r_r_10 s2_tlb_fire_vec_reg\[10\] 1
pff_pin s2_tlb_fire_vec_r_r_9 s2_tlb_fire_vec_reg\[9\] 1
pff_pin s2_tlb_fire_vec_r_r_8 s2_tlb_fire_vec_reg\[8\] 1
pff_pin s2_tlb_fire_vec_r_r_7 s2_tlb_fire_vec_reg\[7\] 1
pff_pin s2_tlb_fire_vec_r_r_6 s2_tlb_fire_vec_reg\[6\] 1
pff_pin s2_tlb_fire_vec_r_r_5 s2_tlb_fire_vec_reg\[5\] 1
pff_pin s2_tlb_fire_vec_r_r_4 s2_tlb_fire_vec_reg\[4\] 1
pff_pin s2_tlb_fire_vec_r_r_3 s2_tlb_fire_vec_reg\[3\] 1
pff_pin s2_tlb_fire_vec_r_r_2 s2_tlb_fire_vec_reg\[2\] 1
pff_pin s2_tlb_fire_vec_r_r_1 s2_tlb_fire_vec_reg\[1\] 1
pff_pin s2_tlb_fire_vec_r_r_0 s2_tlb_fire_vec_reg\[0\] 1
pff_pin s1_tlb_fire_vec_r_r_15 s1_tlb_fire_vec_reg\[15\] 1
pff_pin s1_tlb_fire_vec_r_r_14 s1_tlb_fire_vec_reg\[14\] 1
pff_pin s1_tlb_fire_vec_r_r_13 s1_tlb_fire_vec_reg\[13\] 1
pff_pin s1_tlb_fire_vec_r_r_12 s1_tlb_fire_vec_reg\[12\] 1
pff_pin s1_tlb_fire_vec_r_r_11 s1_tlb_fire_vec_reg\[11\] 1
pff_pin s1_tlb_fire_vec_r_r_10 s1_tlb_fire_vec_reg\[10\] 1
pff_pin s1_tlb_fire_vec_r_r_9 s1_tlb_fire_vec_reg\[9\] 1
pff_pin s1_tlb_fire_vec_r_r_8 s1_tlb_fire_vec_reg\[8\] 1
pff_pin s1_tlb_fire_vec_r_r_7 s1_tlb_fire_vec_reg\[7\] 1
pff_pin s1_tlb_fire_vec_r_r_6 s1_tlb_fire_vec_reg\[6\] 1
pff_pin s1_tlb_fire_vec_r_r_5 s1_tlb_fire_vec_reg\[5\] 1
pff_pin s1_tlb_fire_vec_r_r_4 s1_tlb_fire_vec_reg\[4\] 1
pff_pin s1_tlb_fire_vec_r_r_3 s1_tlb_fire_vec_reg\[3\] 1
pff_pin s1_tlb_fire_vec_r_r_2 s1_tlb_fire_vec_reg\[2\] 1
pff_pin s1_tlb_fire_vec_r_r_1 s1_tlb_fire_vec_reg\[1\] 1
pff_pin s1_tlb_fire_vec_r_r_0 s1_tlb_fire_vec_reg\[0\] 1
pff_pin s1_replace_vec_r s1_replace_vec_r_reg 16
pff_pin s1_hit_r s1_hit_r_reg 1
pff_pin s1_valid_r_last_REG s1_valid_r_last_REG_reg 1
pff_pin entries_0_region_tag entries\[0\].region_tag_reg 11
pff_pin entries_0_region_addr entries\[0\].region_addr_reg 40
pff_pin entries_0_region_bits entries\[0\].region_bits_reg 16
pff_pin entries_0_filter_bits entries\[0\].filter_bits_reg 16
pff_pin entries_0_paddr_valid entries\[0\].paddr_valid_reg 1
pff_pin entries_0_decr_mode entries\[0\].decr_mode_reg 1
pff_pin entries_1_region_tag entries\[1\].region_tag_reg 11
pff_pin entries_1_region_addr entries\[1\].region_addr_reg 40
pff_pin entries_1_region_bits entries\[1\].region_bits_reg 16
pff_pin entries_1_filter_bits entries\[1\].filter_bits_reg 16
pff_pin entries_1_paddr_valid entries\[1\].paddr_valid_reg 1
pff_pin entries_1_decr_mode entries\[1\].decr_mode_reg 1
pff_pin entries_2_region_tag entries\[2\].region_tag_reg 11
pff_pin entries_2_region_addr entries\[2\].region_addr_reg 40
pff_pin entries_2_region_bits entries\[2\].region_bits_reg 16
pff_pin entries_2_filter_bits entries\[2\].filter_bits_reg 16
pff_pin entries_2_paddr_valid entries\[2\].paddr_valid_reg 1
pff_pin entries_2_decr_mode entries\[2\].decr_mode_reg 1
pff_pin entries_3_region_tag entries\[3\].region_tag_reg 11
pff_pin entries_3_region_addr entries\[3\].region_addr_reg 40
pff_pin entries_3_region_bits entries\[3\].region_bits_reg 16
pff_pin entries_3_filter_bits entries\[3\].filter_bits_reg 16
pff_pin entries_3_paddr_valid entries\[3\].paddr_valid_reg 1
pff_pin entries_3_decr_mode entries\[3\].decr_mode_reg 1
pff_pin entries_4_region_tag entries\[4\].region_tag_reg 11
pff_pin entries_4_region_addr entries\[4\].region_addr_reg 40
pff_pin entries_4_region_bits entries\[4\].region_bits_reg 16
pff_pin entries_4_filter_bits entries\[4\].filter_bits_reg 16
pff_pin entries_4_paddr_valid entries\[4\].paddr_valid_reg 1
pff_pin entries_4_decr_mode entries\[4\].decr_mode_reg 1
pff_pin entries_5_region_tag entries\[5\].region_tag_reg 11
pff_pin entries_5_region_addr entries\[5\].region_addr_reg 40
pff_pin entries_5_region_bits entries\[5\].region_bits_reg 16
pff_pin entries_5_filter_bits entries\[5\].filter_bits_reg 16
pff_pin entries_5_paddr_valid entries\[5\].paddr_valid_reg 1
pff_pin entries_5_decr_mode entries\[5\].decr_mode_reg 1
pff_pin entries_6_region_tag entries\[6\].region_tag_reg 11
pff_pin entries_6_region_addr entries\[6\].region_addr_reg 40
pff_pin entries_6_region_bits entries\[6\].region_bits_reg 16
pff_pin entries_6_filter_bits entries\[6\].filter_bits_reg 16
pff_pin entries_6_paddr_valid entries\[6\].paddr_valid_reg 1
pff_pin entries_6_decr_mode entries\[6\].decr_mode_reg 1
pff_pin entries_7_region_tag entries\[7\].region_tag_reg 11
pff_pin entries_7_region_addr entries\[7\].region_addr_reg 40
pff_pin entries_7_region_bits entries\[7\].region_bits_reg 16
pff_pin entries_7_filter_bits entries\[7\].filter_bits_reg 16
pff_pin entries_7_paddr_valid entries\[7\].paddr_valid_reg 1
pff_pin entries_7_decr_mode entries\[7\].decr_mode_reg 1
pff_pin entries_8_region_tag entries\[8\].region_tag_reg 11
pff_pin entries_8_region_addr entries\[8\].region_addr_reg 40
pff_pin entries_8_region_bits entries\[8\].region_bits_reg 16
pff_pin entries_8_filter_bits entries\[8\].filter_bits_reg 16
pff_pin entries_8_paddr_valid entries\[8\].paddr_valid_reg 1
pff_pin entries_8_decr_mode entries\[8\].decr_mode_reg 1
pff_pin entries_9_region_tag entries\[9\].region_tag_reg 11
pff_pin entries_9_region_addr entries\[9\].region_addr_reg 40
pff_pin entries_9_region_bits entries\[9\].region_bits_reg 16
pff_pin entries_9_filter_bits entries\[9\].filter_bits_reg 16
pff_pin entries_9_paddr_valid entries\[9\].paddr_valid_reg 1
pff_pin entries_9_decr_mode entries\[9\].decr_mode_reg 1
pff_pin entries_10_region_tag entries\[10\].region_tag_reg 11
pff_pin entries_10_region_addr entries\[10\].region_addr_reg 40
pff_pin entries_10_region_bits entries\[10\].region_bits_reg 16
pff_pin entries_10_filter_bits entries\[10\].filter_bits_reg 16
pff_pin entries_10_paddr_valid entries\[10\].paddr_valid_reg 1
pff_pin entries_10_decr_mode entries\[10\].decr_mode_reg 1
pff_pin entries_11_region_tag entries\[11\].region_tag_reg 11
pff_pin entries_11_region_addr entries\[11\].region_addr_reg 40
pff_pin entries_11_region_bits entries\[11\].region_bits_reg 16
pff_pin entries_11_filter_bits entries\[11\].filter_bits_reg 16
pff_pin entries_11_paddr_valid entries\[11\].paddr_valid_reg 1
pff_pin entries_11_decr_mode entries\[11\].decr_mode_reg 1
pff_pin entries_12_region_tag entries\[12\].region_tag_reg 11
pff_pin entries_12_region_addr entries\[12\].region_addr_reg 40
pff_pin entries_12_region_bits entries\[12\].region_bits_reg 16
pff_pin entries_12_filter_bits entries\[12\].filter_bits_reg 16
pff_pin entries_12_paddr_valid entries\[12\].paddr_valid_reg 1
pff_pin entries_12_decr_mode entries\[12\].decr_mode_reg 1
pff_pin entries_13_region_tag entries\[13\].region_tag_reg 11
pff_pin entries_13_region_addr entries\[13\].region_addr_reg 40
pff_pin entries_13_region_bits entries\[13\].region_bits_reg 16
pff_pin entries_13_filter_bits entries\[13\].filter_bits_reg 16
pff_pin entries_13_paddr_valid entries\[13\].paddr_valid_reg 1
pff_pin entries_13_decr_mode entries\[13\].decr_mode_reg 1
pff_pin entries_14_region_tag entries\[14\].region_tag_reg 11
pff_pin entries_14_region_addr entries\[14\].region_addr_reg 40
pff_pin entries_14_region_bits entries\[14\].region_bits_reg 16
pff_pin entries_14_filter_bits entries\[14\].filter_bits_reg 16
pff_pin entries_14_paddr_valid entries\[14\].paddr_valid_reg 1
pff_pin entries_14_decr_mode entries\[14\].decr_mode_reg 1
pff_pin entries_15_region_tag entries\[15\].region_tag_reg 11
pff_pin entries_15_region_addr entries\[15\].region_addr_reg 40
pff_pin entries_15_region_bits entries\[15\].region_bits_reg 16
pff_pin entries_15_filter_bits entries\[15\].filter_bits_reg 16
pff_pin entries_15_paddr_valid entries\[15\].paddr_valid_reg 1
pff_pin entries_15_decr_mode entries\[15\].decr_mode_reg 1
pff_pin valids_0 valids_reg\[0\] 1
pff_pin valids_1 valids_reg\[1\] 1
pff_pin valids_2 valids_reg\[2\] 1
pff_pin valids_3 valids_reg\[3\] 1
pff_pin valids_4 valids_reg\[4\] 1
pff_pin valids_5 valids_reg\[5\] 1
pff_pin valids_6 valids_reg\[6\] 1
pff_pin valids_7 valids_reg\[7\] 1
pff_pin valids_8 valids_reg\[8\] 1
pff_pin valids_9 valids_reg\[9\] 1
pff_pin valids_10 valids_reg\[10\] 1
pff_pin valids_11 valids_reg\[11\] 1
pff_pin valids_12 valids_reg\[12\] 1
pff_pin valids_13 valids_reg\[13\] 1
pff_pin valids_14 valids_reg\[14\] 1
pff_pin valids_15 valids_reg\[15\] 1
pff_pin state_reg u_plru/state_reg_reg 15
pff_pin prev_valid_last_REG prev_valid_last_REG_reg 1
pff_pin prev_gen_req_region_tag prev_gen_req_region_tag_reg 11
pff_pin s1_gen_req_region_tag s1_gen_req_region_tag_reg 11
pff_pin s1_gen_req_region_addr s1_gen_req_region_addr_reg 40
pff_pin s1_gen_req_region_bits s1_gen_req_region_bits_reg 16
pff_pin s1_gen_req_paddr_valid s1_gen_req_paddr_valid_reg 1
pff_pin s1_gen_req_decr_mode s1_gen_req_decr_mode_reg 1
pff_pin s1_update_vec s1_update_vec_reg 16
pff_pin s1_tlb_req_valid_last_REG s1_tlb_req_valid_last_REG_reg 1
pff_pin s1_tlb_req_bits_vaddr s1_tlb_req_bits_vaddr_reg 50
pff_pin s1_tlb_req_bits_fullva s1_tlb_req_bits_fullva_reg 64
pff_pin s1_tlb_req_bits_checkfullva s1_tlb_req_bits_checkfullva_reg 1
pff_pin s1_tlb_req_bits_cmd s1_tlb_req_bits_cmd_reg 3
pff_pin s1_tlb_req_bits_hyperinst s1_tlb_req_bits_hyperinst_reg 1
pff_pin s1_tlb_req_bits_hlvx s1_tlb_req_bits_hlvx_reg 1
pff_pin s1_tlb_req_bits_kill s1_tlb_req_bits_kill_reg 1
pff_pin s1_tlb_req_bits_isPrefetch s1_tlb_req_bits_isPrefetch_reg 1
pff_pin s1_tlb_req_bits_no_translate s1_tlb_req_bits_no_translate_reg 1
pff_pin s1_tlb_req_bits_pmp_addr s1_tlb_req_bits_pmp_addr_reg 48
pff_pin s1_tlb_req_bits_frm_mabuf s1_tlb_req_bits_frm_mabuf_reg 1
pff_pin s1_tlb_req_bits_debug_robIdx_flag s1_tlb_req_bits_debug_robIdx_flag_reg 1
pff_pin s1_tlb_req_bits_debug_robIdx_value s1_tlb_req_bits_debug_robIdx_value_reg 8
pff_pin s1_tlb_req_bits_debug_isFirstIssue s1_tlb_req_bits_debug_isFirstIssue_reg 1
pff_pin s3_tlb_resp_fire s3_tlb_resp_fire_reg 1
pff_pin s3_tlb_resp_paddr_0 s3_tlb_resp_paddr_0_reg 48
pff_pin s3_tlb_resp_pbmt_0 s3_tlb_resp_pbmt_0_reg 2
pff_pin s3_tlb_resp_miss s3_tlb_resp_miss_reg 1
pff_pin s3_tlb_resp_excp_0_gpf_ld s3_tlb_resp_excp_0_gpf_ld_reg 1
pff_pin s3_tlb_resp_excp_0_pf_ld s3_tlb_resp_excp_0_pf_ld_reg 1
pff_pin s3_tlb_resp_excp_0_af_ld s3_tlb_resp_excp_0_af_ld_reg 1
puts "PFF_PIN_END PrefetchFilter ok=$::PFF_PIN_OK bad=$::PFF_PIN_BAD"
if {$::PFF_PIN_BAD != 0} { error "PFF_PIN_MISS=$::PFF_PIN_BAD" }
if {$::PFF_PIN_OK != 1792} { error "PFF_PIN_COUNT=$::PFF_PIN_OK expect=1792" }
