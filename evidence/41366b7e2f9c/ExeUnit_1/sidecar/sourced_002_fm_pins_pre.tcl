# ExeUnit_1 FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 10 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 0 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_1_PIN_OK 0
set ::EXEUNIT_1_PIN_BAD 0
proc exeunit_1_pin {r i} {
  set rr "r:/WORK/ExeUnit_1/$r"
  set ii "i:/WORK/ExeUnit_1/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_1_PIN_OK } else {
    incr ::EXEUNIT_1_PIN_BAD
    if {$::EXEUNIT_1_PIN_BAD <= 10} { puts "EXEUNIT_1_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_1_PIN_BEGIN ExeUnit_1 expect=10"
# ---- (a) 外壳寄存器 ----
exeunit_1_pin brh_io_instrAddrTransType_REG_bare_reg u_core/att_q_reg\[0\]\[0\]
exeunit_1_pin brh_io_instrAddrTransType_REG_sv39_reg u_core/att_q_reg\[0\]\[1\]
exeunit_1_pin brh_io_instrAddrTransType_REG_sv39x4_reg u_core/att_q_reg\[0\]\[2\]
exeunit_1_pin brh_io_instrAddrTransType_REG_sv48_reg u_core/att_q_reg\[0\]\[3\]
exeunit_1_pin brh_io_instrAddrTransType_REG_sv48x4_reg u_core/att_q_reg\[0\]\[4\]
exeunit_1_pin jmp_io_instrAddrTransType_REG_bare_reg u_core/att_q_reg\[1\]\[0\]
exeunit_1_pin jmp_io_instrAddrTransType_REG_sv39_reg u_core/att_q_reg\[1\]\[1\]
exeunit_1_pin jmp_io_instrAddrTransType_REG_sv39x4_reg u_core/att_q_reg\[1\]\[2\]
exeunit_1_pin jmp_io_instrAddrTransType_REG_sv48_reg u_core/att_q_reg\[1\]\[3\]
exeunit_1_pin jmp_io_instrAddrTransType_REG_sv48x4_reg u_core/att_q_reg\[1\]\[4\]
puts "EXEUNIT_1_PIN_END ok=$::EXEUNIT_1_PIN_OK bad=$::EXEUNIT_1_PIN_BAD expect=10"
if {$::EXEUNIT_1_PIN_BAD != 0} { error "EXEUNIT_1_PIN_REFUSED=$::EXEUNIT_1_PIN_BAD" }
if {$::EXEUNIT_1_PIN_OK != 10} { error "EXEUNIT_1_PIN_COUNT=$::EXEUNIT_1_PIN_OK expected 10" }
