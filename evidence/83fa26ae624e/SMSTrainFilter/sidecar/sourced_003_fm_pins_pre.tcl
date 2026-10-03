# SMSTrainFilter FM「匹配前」钉点 —— 自动生成：scripts/gen_l1pf_pins.py（勿手改）
#
# 依据见生成器文件头与 verif/fm_target_config/SMSTrainFilter.tcl：这些寄存器 FM 按名配不上且全是 unread，
# 不钉则 vmucp 空转。set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 8 即 error。进 fm.log 的输出一律 ASCII。
set ::L1PF_PIN_EXPECT 8
set ::L1PF_PIN_OK 0
set ::L1PF_PIN_BAD 0
proc l1pf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/SMSTrainFilter/${g}_reg" "i:/WORK/SMSTrainFilter/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/SMSTrainFilter/${g}_reg\[$b\]" "i:/WORK/SMSTrainFilter/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "L1PF_PIN_BEGIN SMSTrainFilter expect=$::L1PF_PIN_EXPECT"
l1pf_pin enqPtrExt_3_flag u_core/enq_flag_reg\[3\] 1
l1pf_pin enqPtrExt_3_value u_core/enq_value_reg\[3\] 3
l1pf_pin enqPtrExt_4_flag u_core/enq_flag_reg\[4\] 1
l1pf_pin enqPtrExt_4_value u_core/enq_value_reg\[4\] 3
puts "L1PF_PIN_END SMSTrainFilter ok=$::L1PF_PIN_OK bad=$::L1PF_PIN_BAD"
if {$::L1PF_PIN_BAD != 0} { error "L1PF_PIN_MISS=$::L1PF_PIN_BAD" }
if {$::L1PF_PIN_OK != 8} { error "L1PF_PIN_COUNT=$::L1PF_PIN_OK expect=8" }
