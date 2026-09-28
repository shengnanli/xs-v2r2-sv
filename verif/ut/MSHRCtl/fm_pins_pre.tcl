# MSHRCtl FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_mshr_pins.py（勿手改）
#
# 只钉 sourceB 实例里的 probe 表项（理由同 verif/ut/SourceB/fm_pins_pre.tcl：waitG[6:4]
# 两侧都是死位，签名配不上）。16 个 MSHR、4 个仲裁器、本层 timers/perf 寄存器 FM 按名
# 自动配上（commit 159b9c25 试跑：除这 12 位外 unmatched 0(0)），不钉。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数不等于字面整数就 error。
set ::MSHRCTL_PIN_EXPECT 224
set ::MSHRCTL_PIN_OK 0
set ::MSHRCTL_PIN_BAD 0
proc mshrctl_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/MSHRCtl/${g}_reg" "i:/WORK/MSHRCtl/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/MSHRCtl/${g}_reg\[$b\]" "i:/WORK/MSHRCtl/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::MSHRCTL_PIN_OK } else {
      incr ::MSHRCTL_PIN_BAD
      if {$::MSHRCTL_PIN_BAD <= 10} { puts "MSHRCTL_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "MSHRCTL_PIN_BEGIN MSHRCtl expect=$::MSHRCTL_PIN_EXPECT"
mshrctl_pin sourceB/probes_0_valid u_core/sourceB/u_core/probes_valid_reg\[0\] 1
mshrctl_pin sourceB/probes_0_rdy u_core/sourceB/u_core/probes_rdy_reg\[0\] 1
mshrctl_pin sourceB/probes_0_waitG u_core/sourceB/u_core/probes_waitG_reg\[0\] 7
mshrctl_pin sourceB/probes_0_task_tag u_core/sourceB/u_core/probes_tag_reg\[0\] 31
mshrctl_pin sourceB/probes_0_task_set u_core/sourceB/u_core/probes_set_reg\[0\] 9
mshrctl_pin sourceB/probes_0_task_opcode u_core/sourceB/u_core/probes_opcode_reg\[0\] 3
mshrctl_pin sourceB/probes_0_task_param u_core/sourceB/u_core/probes_param_reg\[0\] 2
mshrctl_pin sourceB/probes_0_task_alias u_core/sourceB/u_core/probes_alias_reg\[0\] 2
mshrctl_pin sourceB/probes_1_valid u_core/sourceB/u_core/probes_valid_reg\[1\] 1
mshrctl_pin sourceB/probes_1_rdy u_core/sourceB/u_core/probes_rdy_reg\[1\] 1
mshrctl_pin sourceB/probes_1_waitG u_core/sourceB/u_core/probes_waitG_reg\[1\] 7
mshrctl_pin sourceB/probes_1_task_tag u_core/sourceB/u_core/probes_tag_reg\[1\] 31
mshrctl_pin sourceB/probes_1_task_set u_core/sourceB/u_core/probes_set_reg\[1\] 9
mshrctl_pin sourceB/probes_1_task_opcode u_core/sourceB/u_core/probes_opcode_reg\[1\] 3
mshrctl_pin sourceB/probes_1_task_param u_core/sourceB/u_core/probes_param_reg\[1\] 2
mshrctl_pin sourceB/probes_1_task_alias u_core/sourceB/u_core/probes_alias_reg\[1\] 2
mshrctl_pin sourceB/probes_2_valid u_core/sourceB/u_core/probes_valid_reg\[2\] 1
mshrctl_pin sourceB/probes_2_rdy u_core/sourceB/u_core/probes_rdy_reg\[2\] 1
mshrctl_pin sourceB/probes_2_waitG u_core/sourceB/u_core/probes_waitG_reg\[2\] 7
mshrctl_pin sourceB/probes_2_task_tag u_core/sourceB/u_core/probes_tag_reg\[2\] 31
mshrctl_pin sourceB/probes_2_task_set u_core/sourceB/u_core/probes_set_reg\[2\] 9
mshrctl_pin sourceB/probes_2_task_opcode u_core/sourceB/u_core/probes_opcode_reg\[2\] 3
mshrctl_pin sourceB/probes_2_task_param u_core/sourceB/u_core/probes_param_reg\[2\] 2
mshrctl_pin sourceB/probes_2_task_alias u_core/sourceB/u_core/probes_alias_reg\[2\] 2
mshrctl_pin sourceB/probes_3_valid u_core/sourceB/u_core/probes_valid_reg\[3\] 1
mshrctl_pin sourceB/probes_3_rdy u_core/sourceB/u_core/probes_rdy_reg\[3\] 1
mshrctl_pin sourceB/probes_3_waitG u_core/sourceB/u_core/probes_waitG_reg\[3\] 7
mshrctl_pin sourceB/probes_3_task_tag u_core/sourceB/u_core/probes_tag_reg\[3\] 31
mshrctl_pin sourceB/probes_3_task_set u_core/sourceB/u_core/probes_set_reg\[3\] 9
mshrctl_pin sourceB/probes_3_task_opcode u_core/sourceB/u_core/probes_opcode_reg\[3\] 3
mshrctl_pin sourceB/probes_3_task_param u_core/sourceB/u_core/probes_param_reg\[3\] 2
mshrctl_pin sourceB/probes_3_task_alias u_core/sourceB/u_core/probes_alias_reg\[3\] 2
puts "MSHRCTL_PIN_END MSHRCtl ok=$::MSHRCTL_PIN_OK bad=$::MSHRCTL_PIN_BAD"
if {$::MSHRCTL_PIN_BAD != 0} { error "MSHRCTL_PIN_MISS=$::MSHRCTL_PIN_BAD" }
if {$::MSHRCTL_PIN_OK != 224} { error "MSHRCTL_PIN_COUNT=$::MSHRCTL_PIN_OK expect=224" }
