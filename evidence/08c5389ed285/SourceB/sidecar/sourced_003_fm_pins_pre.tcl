# SourceB FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_mshr_pins.py（勿手改）
#
# golden 的 4 个 probe 表项是扁平寄存器 probes_<k>_<字段>，重写核存成按字段的数组
# probes_<字段>[k]。活位靠签名也能配上，但 waitG[6:4]（恒写 0、没有读者）两侧都是
# 死位，签名配不上 —— 所以全部表项寄存器逐位钉死（4 x 56 = 224 位），不依赖签名。
# issueArb（FastArbiter_5）内部同名，FM 自动配对，不钉。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数 set_user_match 的返回值；拒一条或总数不等于字面整数就 error。
set ::SOURCEB_PIN_EXPECT 224
set ::SOURCEB_PIN_OK 0
set ::SOURCEB_PIN_BAD 0
proc sourceb_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/SourceB/${g}_reg" "i:/WORK/SourceB/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/SourceB/${g}_reg\[$b\]" "i:/WORK/SourceB/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::SOURCEB_PIN_OK } else {
      incr ::SOURCEB_PIN_BAD
      if {$::SOURCEB_PIN_BAD <= 10} { puts "SOURCEB_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "SOURCEB_PIN_BEGIN SourceB expect=$::SOURCEB_PIN_EXPECT"
sourceb_pin probes_0_valid u_core/probes_valid_reg\[0\] 1
sourceb_pin probes_0_rdy u_core/probes_rdy_reg\[0\] 1
sourceb_pin probes_0_waitG u_core/probes_waitG_reg\[0\] 7
sourceb_pin probes_0_task_tag u_core/probes_tag_reg\[0\] 31
sourceb_pin probes_0_task_set u_core/probes_set_reg\[0\] 9
sourceb_pin probes_0_task_opcode u_core/probes_opcode_reg\[0\] 3
sourceb_pin probes_0_task_param u_core/probes_param_reg\[0\] 2
sourceb_pin probes_0_task_alias u_core/probes_alias_reg\[0\] 2
sourceb_pin probes_1_valid u_core/probes_valid_reg\[1\] 1
sourceb_pin probes_1_rdy u_core/probes_rdy_reg\[1\] 1
sourceb_pin probes_1_waitG u_core/probes_waitG_reg\[1\] 7
sourceb_pin probes_1_task_tag u_core/probes_tag_reg\[1\] 31
sourceb_pin probes_1_task_set u_core/probes_set_reg\[1\] 9
sourceb_pin probes_1_task_opcode u_core/probes_opcode_reg\[1\] 3
sourceb_pin probes_1_task_param u_core/probes_param_reg\[1\] 2
sourceb_pin probes_1_task_alias u_core/probes_alias_reg\[1\] 2
sourceb_pin probes_2_valid u_core/probes_valid_reg\[2\] 1
sourceb_pin probes_2_rdy u_core/probes_rdy_reg\[2\] 1
sourceb_pin probes_2_waitG u_core/probes_waitG_reg\[2\] 7
sourceb_pin probes_2_task_tag u_core/probes_tag_reg\[2\] 31
sourceb_pin probes_2_task_set u_core/probes_set_reg\[2\] 9
sourceb_pin probes_2_task_opcode u_core/probes_opcode_reg\[2\] 3
sourceb_pin probes_2_task_param u_core/probes_param_reg\[2\] 2
sourceb_pin probes_2_task_alias u_core/probes_alias_reg\[2\] 2
sourceb_pin probes_3_valid u_core/probes_valid_reg\[3\] 1
sourceb_pin probes_3_rdy u_core/probes_rdy_reg\[3\] 1
sourceb_pin probes_3_waitG u_core/probes_waitG_reg\[3\] 7
sourceb_pin probes_3_task_tag u_core/probes_tag_reg\[3\] 31
sourceb_pin probes_3_task_set u_core/probes_set_reg\[3\] 9
sourceb_pin probes_3_task_opcode u_core/probes_opcode_reg\[3\] 3
sourceb_pin probes_3_task_param u_core/probes_param_reg\[3\] 2
sourceb_pin probes_3_task_alias u_core/probes_alias_reg\[3\] 2
puts "SOURCEB_PIN_END SourceB ok=$::SOURCEB_PIN_OK bad=$::SOURCEB_PIN_BAD"
if {$::SOURCEB_PIN_BAD != 0} { error "SOURCEB_PIN_MISS=$::SOURCEB_PIN_BAD" }
if {$::SOURCEB_PIN_OK != 224} { error "SOURCEB_PIN_COUNT=$::SOURCEB_PIN_OK expect=224" }
