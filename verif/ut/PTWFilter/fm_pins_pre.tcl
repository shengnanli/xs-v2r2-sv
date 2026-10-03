# PTWFilter FM「匹配前」钉点 —— 自动生成：scripts/gen_newifu_lane.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟（依据见生成器文件头）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= 所列 golden 寄存器位数之和）就 error。
# 进 fm.log 的输出一律 ASCII。
set ::PTWFILTER_PIN_OK 0
set ::PTWFILTER_PIN_BAD 0
proc ptwfilter_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PTWFilter/${g}_reg" "i:/WORK/PTWFilter/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PTWFilter/${g}_reg\[$b\]" "i:/WORK/PTWFilter/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::PTWFILTER_PIN_OK } else {
      incr ::PTWFILTER_PIN_BAD
      if {$::PTWFILTER_PIN_BAD <= 10} { puts "PTWFILTER_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "PTWFILTER_PIN_BEGIN PTWFilter expect=759"
ptwfilter_pin v_0 u_core/v_q_reg\[0\] 1
ptwfilter_pin v_1 u_core/v_q_reg\[1\] 1
ptwfilter_pin v_2 u_core/v_q_reg\[2\] 1
ptwfilter_pin v_3 u_core/v_q_reg\[3\] 1
ptwfilter_pin v_4 u_core/v_q_reg\[4\] 1
ptwfilter_pin v_5 u_core/v_q_reg\[5\] 1
ptwfilter_pin v_6 u_core/v_q_reg\[6\] 1
ptwfilter_pin v_7 u_core/v_q_reg\[7\] 1
ptwfilter_pin vpn_0 u_core/vpn_q_reg\[0\] 38
ptwfilter_pin vpn_1 u_core/vpn_q_reg\[1\] 38
ptwfilter_pin vpn_2 u_core/vpn_q_reg\[2\] 38
ptwfilter_pin vpn_3 u_core/vpn_q_reg\[3\] 38
ptwfilter_pin vpn_4 u_core/vpn_q_reg\[4\] 38
ptwfilter_pin vpn_5 u_core/vpn_q_reg\[5\] 38
ptwfilter_pin vpn_6 u_core/vpn_q_reg\[6\] 38
ptwfilter_pin vpn_7 u_core/vpn_q_reg\[7\] 38
ptwfilter_pin s2xlate_0 u_core/s2xlate_q_reg\[0\] 2
ptwfilter_pin s2xlate_1 u_core/s2xlate_q_reg\[1\] 2
ptwfilter_pin s2xlate_2 u_core/s2xlate_q_reg\[2\] 2
ptwfilter_pin s2xlate_3 u_core/s2xlate_q_reg\[3\] 2
ptwfilter_pin s2xlate_4 u_core/s2xlate_q_reg\[4\] 2
ptwfilter_pin s2xlate_5 u_core/s2xlate_q_reg\[5\] 2
ptwfilter_pin s2xlate_6 u_core/s2xlate_q_reg\[6\] 2
ptwfilter_pin s2xlate_7 u_core/s2xlate_q_reg\[7\] 2
ptwfilter_pin getGpa_0 u_core/getGpa_q_reg\[0\] 1
ptwfilter_pin getGpa_1 u_core/getGpa_q_reg\[1\] 1
ptwfilter_pin getGpa_2 u_core/getGpa_q_reg\[2\] 1
ptwfilter_pin getGpa_3 u_core/getGpa_q_reg\[3\] 1
ptwfilter_pin getGpa_4 u_core/getGpa_q_reg\[4\] 1
ptwfilter_pin getGpa_5 u_core/getGpa_q_reg\[5\] 1
ptwfilter_pin getGpa_6 u_core/getGpa_q_reg\[6\] 1
ptwfilter_pin getGpa_7 u_core/getGpa_q_reg\[7\] 1
ptwfilter_pin enqPtr u_core/enqPtr_q_reg 3
ptwfilter_pin issPtr u_core/issPtr_q_reg 3
ptwfilter_pin deqPtr u_core/deqPtr_q_reg 3
ptwfilter_pin mayFullDeq u_core/mayFullDeq_q_reg 1
ptwfilter_pin mayFullIss u_core/mayFullIss_q_reg 1
ptwfilter_pin counter u_core/counter_q_reg 4
ptwfilter_pin inflight_counter u_core/inflight_counter_q_reg 4
ptwfilter_pin ptwResp_s2xlate u_core/ptwResp_q_reg\[s2xlate\] 2
ptwfilter_pin ptwResp_s1_entry_tag u_core/ptwResp_q_reg\[s1_entry_tag\] 35
ptwfilter_pin ptwResp_s1_entry_asid u_core/ptwResp_q_reg\[s1_entry_asid\] 16
ptwfilter_pin ptwResp_s1_entry_vmid u_core/ptwResp_q_reg\[s1_entry_vmid\] 14
ptwfilter_pin ptwResp_s1_entry_n u_core/ptwResp_q_reg\[s1_entry_n\] 1
ptwfilter_pin ptwResp_s1_entry_pbmt u_core/ptwResp_q_reg\[s1_entry_pbmt\] 2
ptwfilter_pin ptwResp_s1_entry_perm_d u_core/ptwResp_q_reg\[s1_entry_perm_d\] 1
ptwfilter_pin ptwResp_s1_entry_perm_a u_core/ptwResp_q_reg\[s1_entry_perm_a\] 1
ptwfilter_pin ptwResp_s1_entry_perm_g u_core/ptwResp_q_reg\[s1_entry_perm_g\] 1
ptwfilter_pin ptwResp_s1_entry_perm_u u_core/ptwResp_q_reg\[s1_entry_perm_u\] 1
ptwfilter_pin ptwResp_s1_entry_perm_x u_core/ptwResp_q_reg\[s1_entry_perm_x\] 1
ptwfilter_pin ptwResp_s1_entry_perm_w u_core/ptwResp_q_reg\[s1_entry_perm_w\] 1
ptwfilter_pin ptwResp_s1_entry_perm_r u_core/ptwResp_q_reg\[s1_entry_perm_r\] 1
ptwfilter_pin ptwResp_s1_entry_level u_core/ptwResp_q_reg\[s1_entry_level\] 2
ptwfilter_pin ptwResp_s1_entry_v u_core/ptwResp_q_reg\[s1_entry_v\] 1
ptwfilter_pin ptwResp_s1_entry_ppn u_core/ptwResp_q_reg\[s1_entry_ppn\] 41
ptwfilter_pin ptwResp_s1_addr_low u_core/ptwResp_q_reg\[s1_addr_low\] 3
ptwfilter_pin ptwResp_s1_ppn_low_0 u_core/ptwResp_q_reg\[s1_ppn_low\]\[0\] 3
ptwfilter_pin ptwResp_s1_ppn_low_1 u_core/ptwResp_q_reg\[s1_ppn_low\]\[1\] 3
ptwfilter_pin ptwResp_s1_ppn_low_2 u_core/ptwResp_q_reg\[s1_ppn_low\]\[2\] 3
ptwfilter_pin ptwResp_s1_ppn_low_3 u_core/ptwResp_q_reg\[s1_ppn_low\]\[3\] 3
ptwfilter_pin ptwResp_s1_ppn_low_4 u_core/ptwResp_q_reg\[s1_ppn_low\]\[4\] 3
ptwfilter_pin ptwResp_s1_ppn_low_5 u_core/ptwResp_q_reg\[s1_ppn_low\]\[5\] 3
ptwfilter_pin ptwResp_s1_ppn_low_6 u_core/ptwResp_q_reg\[s1_ppn_low\]\[6\] 3
ptwfilter_pin ptwResp_s1_ppn_low_7 u_core/ptwResp_q_reg\[s1_ppn_low\]\[7\] 3
ptwfilter_pin ptwResp_s1_valididx_0 u_core/ptwResp_q_reg\[s1_valididx\]\[0\] 1
ptwfilter_pin ptwResp_s1_valididx_1 u_core/ptwResp_q_reg\[s1_valididx\]\[1\] 1
ptwfilter_pin ptwResp_s1_valididx_2 u_core/ptwResp_q_reg\[s1_valididx\]\[2\] 1
ptwfilter_pin ptwResp_s1_valididx_3 u_core/ptwResp_q_reg\[s1_valididx\]\[3\] 1
ptwfilter_pin ptwResp_s1_valididx_4 u_core/ptwResp_q_reg\[s1_valididx\]\[4\] 1
ptwfilter_pin ptwResp_s1_valididx_5 u_core/ptwResp_q_reg\[s1_valididx\]\[5\] 1
ptwfilter_pin ptwResp_s1_valididx_6 u_core/ptwResp_q_reg\[s1_valididx\]\[6\] 1
ptwfilter_pin ptwResp_s1_valididx_7 u_core/ptwResp_q_reg\[s1_valididx\]\[7\] 1
ptwfilter_pin ptwResp_s1_pteidx_0 u_core/ptwResp_q_reg\[s1_pteidx\]\[0\] 1
ptwfilter_pin ptwResp_s1_pteidx_1 u_core/ptwResp_q_reg\[s1_pteidx\]\[1\] 1
ptwfilter_pin ptwResp_s1_pteidx_2 u_core/ptwResp_q_reg\[s1_pteidx\]\[2\] 1
ptwfilter_pin ptwResp_s1_pteidx_3 u_core/ptwResp_q_reg\[s1_pteidx\]\[3\] 1
ptwfilter_pin ptwResp_s1_pteidx_4 u_core/ptwResp_q_reg\[s1_pteidx\]\[4\] 1
ptwfilter_pin ptwResp_s1_pteidx_5 u_core/ptwResp_q_reg\[s1_pteidx\]\[5\] 1
ptwfilter_pin ptwResp_s1_pteidx_6 u_core/ptwResp_q_reg\[s1_pteidx\]\[6\] 1
ptwfilter_pin ptwResp_s1_pteidx_7 u_core/ptwResp_q_reg\[s1_pteidx\]\[7\] 1
ptwfilter_pin ptwResp_s1_pf u_core/ptwResp_q_reg\[s1_pf\] 1
ptwfilter_pin ptwResp_s1_af u_core/ptwResp_q_reg\[s1_af\] 1
ptwfilter_pin ptwResp_s2_entry_tag u_core/ptwResp_q_reg\[s2_entry_tag\] 38
ptwfilter_pin ptwResp_s2_entry_vmid u_core/ptwResp_q_reg\[s2_entry_vmid\] 14
ptwfilter_pin ptwResp_s2_entry_n u_core/ptwResp_q_reg\[s2_entry_n\] 1
ptwfilter_pin ptwResp_s2_entry_pbmt u_core/ptwResp_q_reg\[s2_entry_pbmt\] 2
ptwfilter_pin ptwResp_s2_entry_ppn u_core/ptwResp_q_reg\[s2_entry_ppn\] 38
ptwfilter_pin ptwResp_s2_entry_perm_d u_core/ptwResp_q_reg\[s2_entry_perm_d\] 1
ptwfilter_pin ptwResp_s2_entry_perm_a u_core/ptwResp_q_reg\[s2_entry_perm_a\] 1
ptwfilter_pin ptwResp_s2_entry_perm_g u_core/ptwResp_q_reg\[s2_entry_perm_g\] 1
ptwfilter_pin ptwResp_s2_entry_perm_u u_core/ptwResp_q_reg\[s2_entry_perm_u\] 1
ptwfilter_pin ptwResp_s2_entry_perm_x u_core/ptwResp_q_reg\[s2_entry_perm_x\] 1
ptwfilter_pin ptwResp_s2_entry_perm_w u_core/ptwResp_q_reg\[s2_entry_perm_w\] 1
ptwfilter_pin ptwResp_s2_entry_perm_r u_core/ptwResp_q_reg\[s2_entry_perm_r\] 1
ptwfilter_pin ptwResp_s2_entry_level u_core/ptwResp_q_reg\[s2_entry_level\] 2
ptwfilter_pin ptwResp_s2_gpf u_core/ptwResp_q_reg\[s2_gpf\] 1
ptwfilter_pin ptwResp_s2_gaf u_core/ptwResp_q_reg\[s2_gaf\] 1
ptwfilter_pin ptwResp_valid_last_REG u_core/ptwResp_valid_q_reg 1
ptwfilter_pin tlb_req_0_valid_last_REG u_core/tlb_req_valid_q_reg\[0\] 1
ptwfilter_pin tlb_req_0_bits_r_vpn u_core/tlb_req_vpn_q_reg\[0\] 38
ptwfilter_pin tlb_req_0_bits_r_s2xlate u_core/tlb_req_s2xlate_q_reg\[0\] 2
ptwfilter_pin tlb_req_0_bits_r_getGpa u_core/tlb_req_getGpa_q_reg\[0\] 1
ptwfilter_pin tlb_req_1_valid_last_REG u_core/tlb_req_valid_q_reg\[1\] 1
ptwfilter_pin tlb_req_1_bits_r_vpn u_core/tlb_req_vpn_q_reg\[1\] 38
ptwfilter_pin tlb_req_1_bits_r_s2xlate u_core/tlb_req_s2xlate_q_reg\[1\] 2
ptwfilter_pin tlb_req_1_bits_r_getGpa u_core/tlb_req_getGpa_q_reg\[1\] 1
ptwfilter_pin tlb_req_2_valid_last_REG u_core/tlb_req_valid_q_reg\[2\] 1
ptwfilter_pin tlb_req_2_bits_r_vpn u_core/tlb_req_vpn_q_reg\[2\] 38
ptwfilter_pin tlb_req_2_bits_r_s2xlate u_core/tlb_req_s2xlate_q_reg\[2\] 2
ptwfilter_pin tlb_req_2_bits_r_getGpa u_core/tlb_req_getGpa_q_reg\[2\] 1
ptwfilter_pin oldMatchVec_last_REG u_core/oldMatch_q_reg\[0\] 1
ptwfilter_pin oldMatchVec_last_REG_1 u_core/oldMatch_q_reg\[1\] 1
ptwfilter_pin oldMatchVec_last_REG_2 u_core/oldMatch_q_reg\[2\] 1
ptwfilter_pin newMatchVec_last_REG_3 u_core/newMatch10_q_reg 1
ptwfilter_pin newMatchVec_last_REG_6 u_core/newMatch20_q_reg 1
ptwfilter_pin newMatchVec_last_REG_7 u_core/newMatch21_q_reg 1
ptwfilter_pin io_tlb_resp_bits_data_getGpa_REG u_core/resp_getGpa_q_reg 1
puts "PTWFILTER_PIN_END PTWFilter ok=$::PTWFILTER_PIN_OK bad=$::PTWFILTER_PIN_BAD"
if {$::PTWFILTER_PIN_BAD != 0} { error "PTWFILTER_PIN_MISS=$::PTWFILTER_PIN_BAD" }
if {$::PTWFILTER_PIN_OK != 759} { error "PTWFILTER_PIN_COUNT=$::PTWFILTER_PIN_OK expect=759" }
