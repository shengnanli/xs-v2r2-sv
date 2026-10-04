# ExeUnit_9 FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 11 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 0 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_9_PIN_OK 0
set ::EXEUNIT_9_PIN_BAD 0
proc exeunit_9_pin {r i} {
  set rr "r:/WORK/ExeUnit_9/$r"
  set ii "i:/WORK/ExeUnit_9/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_9_PIN_OK } else {
    incr ::EXEUNIT_9_PIN_BAD
    if {$::EXEUNIT_9_PIN_BAD <= 10} { puts "EXEUNIT_9_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_9_PIN_BEGIN ExeUnit_9 expect=11"
# ---- (a) 外壳寄存器 ----
exeunit_9_pin busy_reg u_core/g_busy.busy_q_reg
exeunit_9_pin robIdx_flag_reg u_core/g_busy.rob_q_reg\[8\]
exeunit_9_pin robIdx_value_reg\[0\] u_core/g_busy.rob_q_reg\[0\]
exeunit_9_pin robIdx_value_reg\[1\] u_core/g_busy.rob_q_reg\[1\]
exeunit_9_pin robIdx_value_reg\[2\] u_core/g_busy.rob_q_reg\[2\]
exeunit_9_pin robIdx_value_reg\[3\] u_core/g_busy.rob_q_reg\[3\]
exeunit_9_pin robIdx_value_reg\[4\] u_core/g_busy.rob_q_reg\[4\]
exeunit_9_pin robIdx_value_reg\[5\] u_core/g_busy.rob_q_reg\[5\]
exeunit_9_pin robIdx_value_reg\[6\] u_core/g_busy.rob_q_reg\[6\]
exeunit_9_pin robIdx_value_reg\[7\] u_core/g_busy.rob_q_reg\[7\]
exeunit_9_pin uncer_en_reg_reg u_core/g_fu\[0\].g_unc.uncer_q_reg
puts "EXEUNIT_9_PIN_END ok=$::EXEUNIT_9_PIN_OK bad=$::EXEUNIT_9_PIN_BAD expect=11"
if {$::EXEUNIT_9_PIN_BAD != 0} { error "EXEUNIT_9_PIN_REFUSED=$::EXEUNIT_9_PIN_BAD" }
if {$::EXEUNIT_9_PIN_OK != 11} { error "EXEUNIT_9_PIN_COUNT=$::EXEUNIT_9_PIN_OK expected 11" }
