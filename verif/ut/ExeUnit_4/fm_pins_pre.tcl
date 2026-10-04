# ExeUnit_4 FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 0 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 0 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_4_PIN_OK 0
set ::EXEUNIT_4_PIN_BAD 0
proc exeunit_4_pin {r i} {
  set rr "r:/WORK/ExeUnit_4/$r"
  set ii "i:/WORK/ExeUnit_4/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_4_PIN_OK } else {
    incr ::EXEUNIT_4_PIN_BAD
    if {$::EXEUNIT_4_PIN_BAD <= 10} { puts "EXEUNIT_4_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_4_PIN_BEGIN ExeUnit_4 expect=0"
# ---- (a) 外壳寄存器 ----
puts "EXEUNIT_4_PIN_END ok=$::EXEUNIT_4_PIN_OK bad=$::EXEUNIT_4_PIN_BAD expect=0"
if {$::EXEUNIT_4_PIN_BAD != 0} { error "EXEUNIT_4_PIN_REFUSED=$::EXEUNIT_4_PIN_BAD" }
if {$::EXEUNIT_4_PIN_OK != 0} { error "EXEUNIT_4_PIN_COUNT=$::EXEUNIT_4_PIN_OK expected 0" }
