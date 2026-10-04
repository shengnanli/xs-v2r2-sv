# CSA_Nto2With3to2MainPipeline FM「匹配前」钉点 —— 自动生成：scripts/gen_fma_pins.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写件（u_core / g_fmt[f].u_fmt / 压缩树 level4_q）之间的命名鸿沟；
# 钉的是 CSA_Nto2With3to2MainPipeline 子树（4 个 golden 寄存器 / 428 位）。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。
set ::FMAPIN_OK 0
set ::FMAPIN_BAD 0
proc fmapin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/CSA_Nto2With3to2MainPipeline/${g}" "i:/WORK/CSA_Nto2With3to2MainPipeline/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/CSA_Nto2With3to2MainPipeline/${g}\[$b\]" "i:/WORK/CSA_Nto2With3to2MainPipeline/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::FMAPIN_OK } else {
      incr ::FMAPIN_BAD
      if {$::FMAPIN_BAD <= 10} { puts "FMAPIN_FAIL: $r <-> $m" }
    }
  }
}
puts "FMAPIN_BEGIN CSA_Nto2With3to2MainPipeline expect=428"
fmapin U_CSA4to2_io_in_a_r_reg u_core/level4_q_reg\[0\] 107
fmapin U_CSA4to2_io_in_b_r_reg u_core/level4_q_reg\[1\] 107
fmapin U_CSA4to2_io_in_c_r_reg u_core/level4_q_reg\[2\] 107
fmapin U_CSA4to2_io_in_d_r_reg u_core/level4_q_reg\[3\] 107
puts "FMAPIN_END CSA_Nto2With3to2MainPipeline ok=$::FMAPIN_OK bad=$::FMAPIN_BAD"
if {$::FMAPIN_BAD != 0} { error "FMAPIN_MISS=$::FMAPIN_BAD" }
if {$::FMAPIN_OK != 428} { error "FMAPIN_COUNT=$::FMAPIN_OK expect=428" }
