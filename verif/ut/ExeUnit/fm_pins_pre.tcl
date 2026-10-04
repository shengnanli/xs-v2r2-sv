# ExeUnit FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）
#
# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。
# (a) 外壳寄存器 44 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；
# (b) 子 FU 签核时用过的钉点 18 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。
# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。
set ::EXEUNIT_PIN_OK 0
set ::EXEUNIT_PIN_BAD 0
proc exeunit_pin {r i} {
  set rr "r:/WORK/ExeUnit/$r"
  set ii "i:/WORK/ExeUnit/$i"
  if {[set_user_match $rr $ii]} { incr ::EXEUNIT_PIN_OK } else {
    incr ::EXEUNIT_PIN_BAD
    if {$::EXEUNIT_PIN_BAD <= 10} { puts "EXEUNIT_PIN_FAIL: $rr <-> $ii" }
  }
}
puts "EXEUNIT_PIN_BEGIN ExeUnit expect=62"
# ---- (a) 外壳寄存器 ----
exeunit_pin fuVldVec_1_reg u_core/g_fu\[1\].g_lat.vld_q_reg\[1\]
exeunit_pin fuVldVec_1_1_reg u_core/g_fu\[2\].g_lat.vld_q_reg\[1\]
exeunit_pin fuVldVec_2_reg u_core/g_fu\[1\].g_lat.vld_q_reg\[2\]
exeunit_pin fuVldVec_2_1_reg u_core/g_fu\[2\].g_lat.vld_q_reg\[2\]
exeunit_pin fuVld_en_reg_1_reg u_core/g_fu\[1\].g_lat.en_q_reg
exeunit_pin fuVld_en_reg_2_reg u_core/g_fu\[2\].g_lat.en_q_reg
exeunit_pin inPipe_1_1_pdest_reg\[0\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[0\]
exeunit_pin inPipe_1_1_pdest_reg\[1\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[1\]
exeunit_pin inPipe_1_1_pdest_reg\[2\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[2\]
exeunit_pin inPipe_1_1_pdest_reg\[3\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[3\]
exeunit_pin inPipe_1_1_pdest_reg\[4\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[4\]
exeunit_pin inPipe_1_1_pdest_reg\[5\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[5\]
exeunit_pin inPipe_1_1_pdest_reg\[6\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[6\]
exeunit_pin inPipe_1_1_pdest_reg\[7\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[1\]\[7\]
exeunit_pin inPipe_1_1_rfWen_reg u_core/g_pipe.g_fld\[2\].g_reg.q_reg\[1\]\[0\]
exeunit_pin inPipe_1_1_robIdx_flag_reg u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[8\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[0\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[0\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[1\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[1\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[2\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[2\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[3\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[3\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[4\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[4\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[5\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[5\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[6\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[6\]
exeunit_pin inPipe_1_1_robIdx_value_reg\[7\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[1\]\[7\]
exeunit_pin inPipe_1_2_pdest_reg\[0\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[0\]
exeunit_pin inPipe_1_2_pdest_reg\[1\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[1\]
exeunit_pin inPipe_1_2_pdest_reg\[2\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[2\]
exeunit_pin inPipe_1_2_pdest_reg\[3\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[3\]
exeunit_pin inPipe_1_2_pdest_reg\[4\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[4\]
exeunit_pin inPipe_1_2_pdest_reg\[5\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[5\]
exeunit_pin inPipe_1_2_pdest_reg\[6\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[6\]
exeunit_pin inPipe_1_2_pdest_reg\[7\] u_core/g_pipe.g_fld\[1\].g_reg.q_reg\[2\]\[7\]
exeunit_pin inPipe_1_2_rfWen_reg u_core/g_pipe.g_fld\[2\].g_reg.q_reg\[2\]\[0\]
exeunit_pin inPipe_1_2_robIdx_flag_reg u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[8\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[0\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[0\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[1\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[1\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[2\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[2\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[3\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[3\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[4\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[4\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[5\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[5\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[6\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[6\]
exeunit_pin inPipe_1_2_robIdx_value_reg\[7\] u_core/g_pipe.g_fld\[0\].g_reg.q_reg\[2\]\[7\]
exeunit_pin inPipe_2_1_reg u_core/g_pipe.stage_valid_q_reg\[1\]
exeunit_pin inPipe_2_2_reg u_core/g_pipe.stage_valid_q_reg\[2\]
# ---- (b) Bku（Bku）：verif/ut/Bku/fm_pins_pre.tcl 的调用序列 ----
exeunit_pin Bku/funcReg_reg\[0\] Bku/u_core/func_s1_reg\[0\]
exeunit_pin Bku/funcReg_reg\[1\] Bku/u_core/func_s1_reg\[1\]
exeunit_pin Bku/funcReg_reg\[2\] Bku/u_core/func_s1_reg\[2\]
exeunit_pin Bku/funcReg_reg\[3\] Bku/u_core/func_s1_reg\[3\]
exeunit_pin Bku/funcReg_reg\[4\] Bku/u_core/func_s1_reg\[4\]
exeunit_pin Bku/funcReg_reg\[5\] Bku/u_core/func_s1_reg\[5\]
exeunit_pin Bku/funcReg_reg\[6\] Bku/u_core/func_s1_reg\[6\]
exeunit_pin Bku/funcReg_reg\[7\] Bku/u_core/func_s1_reg\[7\]
exeunit_pin Bku/funcReg_reg\[8\] Bku/u_core/func_s1_reg\[8\]
exeunit_pin Bku/countModule/funcReg_reg\[0\] Bku/u_core/countModule/u_core/funcReg_reg\[0\]
exeunit_pin Bku/countModule/funcReg_reg\[1\] Bku/u_core/countModule/u_core/funcReg_reg\[1\]
exeunit_pin Bku/countModule/funcReg_reg\[2\] Bku/u_core/countModule/u_core/funcReg_reg\[2\]
exeunit_pin Bku/countModule/funcReg_reg\[3\] Bku/u_core/countModule/u_core/funcReg_reg\[3\]
exeunit_pin Bku/countModule/funcReg_reg\[4\] Bku/u_core/countModule/u_core/funcReg_reg\[4\]
exeunit_pin Bku/countModule/funcReg_reg\[5\] Bku/u_core/countModule/u_core/funcReg_reg\[5\]
exeunit_pin Bku/countModule/funcReg_reg\[6\] Bku/u_core/countModule/u_core/funcReg_reg\[6\]
exeunit_pin Bku/countModule/funcReg_reg\[7\] Bku/u_core/countModule/u_core/funcReg_reg\[7\]
exeunit_pin Bku/countModule/funcReg_reg\[8\] Bku/u_core/countModule/u_core/funcReg_reg\[8\]
puts "EXEUNIT_PIN_END ok=$::EXEUNIT_PIN_OK bad=$::EXEUNIT_PIN_BAD expect=62"
if {$::EXEUNIT_PIN_BAD != 0} { error "EXEUNIT_PIN_REFUSED=$::EXEUNIT_PIN_BAD" }
if {$::EXEUNIT_PIN_OK != 62} { error "EXEUNIT_PIN_COUNT=$::EXEUNIT_PIN_OK expected 62" }
