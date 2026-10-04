# ExeUnit_7 FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 13 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 6 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_7_PIN_OK 0
set ::EXEUNIT_7_PIN_BAD 0
proc exeunit_7_pin {r i} {
  set rr "r:/WORK/ExeUnit_7/$r"
  set ii "i:/WORK/ExeUnit_7/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_7_PIN_OK } else {
    incr ::EXEUNIT_7_PIN_BAD
    if {$::EXEUNIT_7_PIN_BAD <= 10} { puts "EXEUNIT_7_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_7_PIN_BEGIN ExeUnit_7 expect=19"
# ---- (a) 外壳寄存器 ----
exeunit_7_pin busy_reg u_core/g_busy.busy_q_reg
exeunit_7_pin io_error_0_REG_reg u_err/stage1_q_reg\[0\]
exeunit_7_pin io_error_0_REG_1_reg u_err/stage2_q_reg\[0\]
exeunit_7_pin robIdx_flag_reg u_core/g_busy.rob_q_reg\[8\]
exeunit_7_pin robIdx_value_reg\[0\] u_core/g_busy.rob_q_reg\[0\]
exeunit_7_pin robIdx_value_reg\[1\] u_core/g_busy.rob_q_reg\[1\]
exeunit_7_pin robIdx_value_reg\[2\] u_core/g_busy.rob_q_reg\[2\]
exeunit_7_pin robIdx_value_reg\[3\] u_core/g_busy.rob_q_reg\[3\]
exeunit_7_pin robIdx_value_reg\[4\] u_core/g_busy.rob_q_reg\[4\]
exeunit_7_pin robIdx_value_reg\[5\] u_core/g_busy.rob_q_reg\[5\]
exeunit_7_pin robIdx_value_reg\[6\] u_core/g_busy.rob_q_reg\[6\]
exeunit_7_pin robIdx_value_reg\[7\] u_core/g_busy.rob_q_reg\[7\]
exeunit_7_pin uncer_en_reg_2_reg u_core/g_fu\[2\].g_unc.uncer_q_reg
# ---- (c) Div（DivUnit 外壳附加）：gen_exeunit.py EXTRA_CHILD_PINS（依据见该表注释）----
exeunit_7_pin Div/divDataModule/aLZCReg_reg\[6\] Div/u_core/u_div/u_core/aLZCReg_reg\[6\]
exeunit_7_pin Div/divDataModule/dLZCReg_reg\[6\] Div/u_core/u_div/u_core/dLZCReg_reg\[6\]
exeunit_7_pin Div/divDataModule/udNegReg_0_reg\[67\] Div/u_core/u_div/u_core/udNegReg_0_reg\[67\]
exeunit_7_pin Div/divDataModule/udNegReg_1_reg\[67\] Div/u_core/u_div/u_core/udNegReg_1_reg\[67\]
exeunit_7_pin Div/divDataModule/udNegReg_3_reg\[67\] Div/u_core/u_div/u_core/udNegReg_3_reg\[67\]
exeunit_7_pin Div/divDataModule/udNegReg_4_reg\[67\] Div/u_core/u_div/u_core/udNegReg_4_reg\[67\]
puts "EXEUNIT_7_PIN_END ok=$::EXEUNIT_7_PIN_OK bad=$::EXEUNIT_7_PIN_BAD expect=19"
if {$::EXEUNIT_7_PIN_BAD != 0} { error "EXEUNIT_7_PIN_REFUSED=$::EXEUNIT_7_PIN_BAD" }
if {$::EXEUNIT_7_PIN_OK != 19} { error "EXEUNIT_7_PIN_COUNT=$::EXEUNIT_7_PIN_OK expected 19" }
