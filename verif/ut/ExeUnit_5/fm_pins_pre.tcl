# ExeUnit_5 FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 53 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 0 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_5_PIN_OK 0
set ::EXEUNIT_5_PIN_BAD 0
proc exeunit_5_pin {r i} {
  set rr "r:/WORK/ExeUnit_5/$r"
  set ii "i:/WORK/ExeUnit_5/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_5_PIN_OK } else {
    incr ::EXEUNIT_5_PIN_BAD
    if {$::EXEUNIT_5_PIN_BAD <= 10} { puts "EXEUNIT_5_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_5_PIN_BEGIN ExeUnit_5 expect=53"
# ---- (a) 外壳寄存器 ----
exeunit_5_pin brh_io_instrAddrTransType_REG_bare_reg u_core/att_q_reg\[0\]\[0\]
exeunit_5_pin brh_io_instrAddrTransType_REG_sv39_reg u_core/att_q_reg\[0\]\[1\]
exeunit_5_pin brh_io_instrAddrTransType_REG_sv39x4_reg u_core/att_q_reg\[0\]\[2\]
exeunit_5_pin brh_io_instrAddrTransType_REG_sv48_reg u_core/att_q_reg\[0\]\[3\]
exeunit_5_pin brh_io_instrAddrTransType_REG_sv48x4_reg u_core/att_q_reg\[0\]\[4\]
exeunit_5_pin fuVldVec_1_reg u_core/g_fu\[2\].g_lat.vld_q_reg\[1\]
exeunit_5_pin fuVldVec_2_reg u_core/g_fu\[2\].g_lat.vld_q_reg\[2\]
exeunit_5_pin fuVld_en_reg_2_reg u_core/g_fu\[2\].g_lat.en_q_reg
exeunit_5_pin inPipe_1_1_fpWen_reg u_core/g_pipe.g_fld\[2\].g_reg.q_reg\[1\]\[0\]
exeunit_5_pin inPipe_1_1_fpu_wflags_reg u_core/g_pipe.g_fld\[3\].g_reg.q_reg\[1\]\[0\]
exeunit_5_pin inPipe_1_1_pdest_reg\[0\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[0\]
exeunit_5_pin inPipe_1_1_pdest_reg\[1\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[1\]
exeunit_5_pin inPipe_1_1_pdest_reg\[2\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[2\]
exeunit_5_pin inPipe_1_1_pdest_reg\[3\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[3\]
exeunit_5_pin inPipe_1_1_pdest_reg\[4\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[4\]
exeunit_5_pin inPipe_1_1_pdest_reg\[5\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[5\]
exeunit_5_pin inPipe_1_1_pdest_reg\[6\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[6\]
exeunit_5_pin inPipe_1_1_pdest_reg\[7\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[7\]
exeunit_5_pin inPipe_1_1_robIdx_flag_reg u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[8\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[0\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[0\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[1\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[1\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[2\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[2\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[3\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[3\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[4\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[4\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[5\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[5\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[6\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[6\]
exeunit_5_pin inPipe_1_1_robIdx_value_reg\[7\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[7\]
exeunit_5_pin inPipe_1_2_fpWen_reg u_core/g_pipe.g_fld\[2\].g_reg.q_reg\[2\]\[0\]
exeunit_5_pin inPipe_1_2_fpu_wflags_reg u_core/g_pipe.g_fld\[3\].g_reg.q_reg\[2\]\[0\]
exeunit_5_pin inPipe_1_2_pdest_reg\[0\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[0\]
exeunit_5_pin inPipe_1_2_pdest_reg\[1\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[1\]
exeunit_5_pin inPipe_1_2_pdest_reg\[2\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[2\]
exeunit_5_pin inPipe_1_2_pdest_reg\[3\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[3\]
exeunit_5_pin inPipe_1_2_pdest_reg\[4\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[4\]
exeunit_5_pin inPipe_1_2_pdest_reg\[5\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[5\]
exeunit_5_pin inPipe_1_2_pdest_reg\[6\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[6\]
exeunit_5_pin inPipe_1_2_pdest_reg\[7\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[7\]
exeunit_5_pin inPipe_1_2_robIdx_flag_reg u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[8\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[0\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[0\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[1\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[1\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[2\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[2\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[3\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[3\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[4\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[4\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[5\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[5\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[6\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[6\]
exeunit_5_pin inPipe_1_2_robIdx_value_reg\[7\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[7\]
exeunit_5_pin inPipe_2_1_reg u_core/g_pipe.stage_valid_q_reg\[1\]
exeunit_5_pin inPipe_2_2_reg u_core/g_pipe.stage_valid_q_reg\[2\]
exeunit_5_pin jmp_io_instrAddrTransType_REG_bare_reg u_core/att_q_reg\[1\]\[0\]
exeunit_5_pin jmp_io_instrAddrTransType_REG_sv39_reg u_core/att_q_reg\[1\]\[1\]
exeunit_5_pin jmp_io_instrAddrTransType_REG_sv39x4_reg u_core/att_q_reg\[1\]\[2\]
exeunit_5_pin jmp_io_instrAddrTransType_REG_sv48_reg u_core/att_q_reg\[1\]\[3\]
exeunit_5_pin jmp_io_instrAddrTransType_REG_sv48x4_reg u_core/att_q_reg\[1\]\[4\]
puts "EXEUNIT_5_PIN_END ok=$::EXEUNIT_5_PIN_OK bad=$::EXEUNIT_5_PIN_BAD expect=53"
if {$::EXEUNIT_5_PIN_BAD != 0} { error "EXEUNIT_5_PIN_REFUSED=$::EXEUNIT_5_PIN_BAD" }
if {$::EXEUNIT_5_PIN_OK != 53} { error "EXEUNIT_5_PIN_COUNT=$::EXEUNIT_5_PIN_OK expected 53" }
