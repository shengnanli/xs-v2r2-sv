# PrefetchQueue FM「匹配前」钉点 —— 自动生成：scripts/gen_l1pf_pins.py（勿手改）
#
# 依据见生成器文件头与 verif/fm_target_config/PrefetchQueue.tcl：这些寄存器 FM 按名配不上且全是 unread，
# 不钉则 vmucp 空转。set_user_match 只声明对应，比较照比，不约束 ref、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 31 即 error。进 fm.log 的输出一律 ASCII。
set ::L1PF_PIN_EXPECT 31
set ::L1PF_PIN_OK 0
set ::L1PF_PIN_BAD 0
proc l1pf_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PrefetchQueue/${g}_reg" "i:/WORK/PrefetchQueue/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PrefetchQueue/${g}_reg\[$b\]" "i:/WORK/PrefetchQueue/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::L1PF_PIN_OK } else {
      incr ::L1PF_PIN_BAD
      if {$::L1PF_PIN_BAD <= 10} { puts "L1PF_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "L1PF_PIN_BEGIN PrefetchQueue expect=$::L1PF_PIN_EXPECT"
l1pf_pin valids_0 u_core/queue_valid_reg\[0\] 1
l1pf_pin valids_1 u_core/queue_valid_reg\[1\] 1
l1pf_pin valids_2 u_core/queue_valid_reg\[2\] 1
l1pf_pin valids_3 u_core/queue_valid_reg\[3\] 1
l1pf_pin valids_4 u_core/queue_valid_reg\[4\] 1
l1pf_pin valids_5 u_core/queue_valid_reg\[5\] 1
l1pf_pin valids_6 u_core/queue_valid_reg\[6\] 1
l1pf_pin valids_7 u_core/queue_valid_reg\[7\] 1
l1pf_pin valids_8 u_core/queue_valid_reg\[8\] 1
l1pf_pin valids_9 u_core/queue_valid_reg\[9\] 1
l1pf_pin valids_10 u_core/queue_valid_reg\[10\] 1
l1pf_pin valids_11 u_core/queue_valid_reg\[11\] 1
l1pf_pin valids_12 u_core/queue_valid_reg\[12\] 1
l1pf_pin valids_13 u_core/queue_valid_reg\[13\] 1
l1pf_pin valids_14 u_core/queue_valid_reg\[14\] 1
l1pf_pin valids_15 u_core/queue_valid_reg\[15\] 1
l1pf_pin valids_16 u_core/queue_valid_reg\[16\] 1
l1pf_pin valids_17 u_core/queue_valid_reg\[17\] 1
l1pf_pin valids_18 u_core/queue_valid_reg\[18\] 1
l1pf_pin valids_19 u_core/queue_valid_reg\[19\] 1
l1pf_pin valids_20 u_core/queue_valid_reg\[20\] 1
l1pf_pin valids_21 u_core/queue_valid_reg\[21\] 1
l1pf_pin valids_22 u_core/queue_valid_reg\[22\] 1
l1pf_pin valids_23 u_core/queue_valid_reg\[23\] 1
l1pf_pin valids_24 u_core/queue_valid_reg\[24\] 1
l1pf_pin valids_25 u_core/queue_valid_reg\[25\] 1
l1pf_pin valids_26 u_core/queue_valid_reg\[26\] 1
l1pf_pin valids_27 u_core/queue_valid_reg\[27\] 1
l1pf_pin valids_28 u_core/queue_valid_reg\[28\] 1
l1pf_pin valids_29 u_core/queue_valid_reg\[29\] 1
l1pf_pin valids_30 u_core/queue_valid_reg\[30\] 1
puts "L1PF_PIN_END PrefetchQueue ok=$::L1PF_PIN_OK bad=$::L1PF_PIN_BAD"
if {$::L1PF_PIN_BAD != 0} { error "L1PF_PIN_MISS=$::L1PF_PIN_BAD" }
if {$::L1PF_PIN_OK != 31} { error "L1PF_PIN_COUNT=$::L1PF_PIN_OK expect=31" }
