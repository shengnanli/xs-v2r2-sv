# PrefetchReqBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_l1pf_pins.py（勿手改）
#
# 依据见生成器文件头与 verif/fm_target_config/PrefetchReqBuffer.tcl：这些寄存器 FM 按名配不上且全是 unread，
# 不钉则 vmucp 空转。set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 146 即 error。进 fm.log 的输出一律 ASCII。
set ::L1PF_PIN_EXPECT 146
set ::L1PF_PIN_OK 0
set ::L1PF_PIN_BAD 0
proc l1pf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PrefetchReqBuffer/${g}_reg" "i:/WORK/PrefetchReqBuffer/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PrefetchReqBuffer/${g}_reg\[$b\]" "i:/WORK/PrefetchReqBuffer/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "L1PF_PIN_BEGIN PrefetchReqBuffer expect=$::L1PF_PIN_EXPECT"
proc l1pf_pin_bits {g i bits} {
  foreach b $bits {
    set r "r:/WORK/PrefetchReqBuffer/${g}_reg\[$b\]"
    set m "i:/WORK/PrefetchReqBuffer/${i}\[$b\]"
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
l1pf_pin_bits entries_0_paddrNoOffset u_core/ent_paddrNoOffset_reg\[0\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_1_paddrNoOffset u_core/ent_paddrNoOffset_reg\[1\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_2_paddrNoOffset u_core/ent_paddrNoOffset_reg\[2\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_3_paddrNoOffset u_core/ent_paddrNoOffset_reg\[3\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_4_paddrNoOffset u_core/ent_paddrNoOffset_reg\[4\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_5_paddrNoOffset u_core/ent_paddrNoOffset_reg\[5\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_6_paddrNoOffset u_core/ent_paddrNoOffset_reg\[6\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_7_paddrNoOffset u_core/ent_paddrNoOffset_reg\[7\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_8_paddrNoOffset u_core/ent_paddrNoOffset_reg\[8\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_9_paddrNoOffset u_core/ent_paddrNoOffset_reg\[9\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_10_paddrNoOffset u_core/ent_paddrNoOffset_reg\[10\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_11_paddrNoOffset u_core/ent_paddrNoOffset_reg\[11\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_12_paddrNoOffset u_core/ent_paddrNoOffset_reg\[12\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_13_paddrNoOffset u_core/ent_paddrNoOffset_reg\[13\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_14_paddrNoOffset u_core/ent_paddrNoOffset_reg\[14\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits entries_15_paddrNoOffset u_core/ent_paddrNoOffset_reg\[15\] {42 43 44 45 46 47 48 49}
l1pf_pin_bits prev_in_req_full_vaddr u_core/prev_in_full_vaddr_reg {0 1 2 3 4 5}
l1pf_pin_bits s1_in_req_full_vaddr u_core/s1_in_full_vaddr_reg {0 1 2 3 4 5}
l1pf_pin_bits s3_tlb_resp_paddr_0 u_core/s3_tlb_resp_paddr_reg {0 1 2 3 4 5}
puts "L1PF_PIN_END PrefetchReqBuffer ok=$::L1PF_PIN_OK bad=$::L1PF_PIN_BAD"
if {$::L1PF_PIN_BAD != 0} { error "L1PF_PIN_MISS=$::L1PF_PIN_BAD" }
if {$::L1PF_PIN_OK != 146} { error "L1PF_PIN_COUNT=$::L1PF_PIN_OK expect=146" }
