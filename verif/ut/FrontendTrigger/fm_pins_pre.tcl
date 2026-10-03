# FrontendTrigger FM「匹配前」钉点 —— 自动生成：scripts/gen_newifu_lane.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟（依据见生成器文件头）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= 所列 golden 寄存器位数之和）就 error。
# 进 fm.log 的输出一律 ASCII。
set ::FRONTENDTRIGGER_PIN_OK 0
set ::FRONTENDTRIGGER_PIN_BAD 0
proc frontendtrigger_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/FrontendTrigger/${g}_reg" "i:/WORK/FrontendTrigger/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/FrontendTrigger/${g}_reg\[$b\]" "i:/WORK/FrontendTrigger/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::FRONTENDTRIGGER_PIN_OK } else {
      incr ::FRONTENDTRIGGER_PIN_BAD
      if {$::FRONTENDTRIGGER_PIN_BAD <= 10} { puts "FRONTENDTRIGGER_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "FRONTENDTRIGGER_PIN_BEGIN FrontendTrigger expect=296"
frontendtrigger_pin tdataVec_0_matchType u_core/tdata_matchType_q_reg\[0\] 2
frontendtrigger_pin tdataVec_0_select u_core/tdata_select_q_reg\[0\] 1
frontendtrigger_pin tdataVec_0_timing u_core/tdata_timing_q_reg\[0\] 1
frontendtrigger_pin tdataVec_0_action u_core/tdata_action_q_reg\[0\] 4
frontendtrigger_pin tdataVec_0_chain u_core/tdata_chain_q_reg\[0\] 1
frontendtrigger_pin tdataVec_0_tdata2 u_core/tdata_tdata2_q_reg\[0\] 64
frontendtrigger_pin tdataVec_1_matchType u_core/tdata_matchType_q_reg\[1\] 2
frontendtrigger_pin tdataVec_1_select u_core/tdata_select_q_reg\[1\] 1
frontendtrigger_pin tdataVec_1_timing u_core/tdata_timing_q_reg\[1\] 1
frontendtrigger_pin tdataVec_1_action u_core/tdata_action_q_reg\[1\] 4
frontendtrigger_pin tdataVec_1_chain u_core/tdata_chain_q_reg\[1\] 1
frontendtrigger_pin tdataVec_1_tdata2 u_core/tdata_tdata2_q_reg\[1\] 64
frontendtrigger_pin tdataVec_2_matchType u_core/tdata_matchType_q_reg\[2\] 2
frontendtrigger_pin tdataVec_2_select u_core/tdata_select_q_reg\[2\] 1
frontendtrigger_pin tdataVec_2_timing u_core/tdata_timing_q_reg\[2\] 1
frontendtrigger_pin tdataVec_2_action u_core/tdata_action_q_reg\[2\] 4
frontendtrigger_pin tdataVec_2_chain u_core/tdata_chain_q_reg\[2\] 1
frontendtrigger_pin tdataVec_2_tdata2 u_core/tdata_tdata2_q_reg\[2\] 64
frontendtrigger_pin tdataVec_3_matchType u_core/tdata_matchType_q_reg\[3\] 2
frontendtrigger_pin tdataVec_3_select u_core/tdata_select_q_reg\[3\] 1
frontendtrigger_pin tdataVec_3_timing u_core/tdata_timing_q_reg\[3\] 1
frontendtrigger_pin tdataVec_3_action u_core/tdata_action_q_reg\[3\] 4
frontendtrigger_pin tdataVec_3_chain u_core/tdata_chain_q_reg\[3\] 1
frontendtrigger_pin tdataVec_3_tdata2 u_core/tdata_tdata2_q_reg\[3\] 64
frontendtrigger_pin triggerEnableVec_0 u_core/enable_q_reg\[0\] 1
frontendtrigger_pin triggerEnableVec_1 u_core/enable_q_reg\[1\] 1
frontendtrigger_pin triggerEnableVec_2 u_core/enable_q_reg\[2\] 1
frontendtrigger_pin triggerEnableVec_3 u_core/enable_q_reg\[3\] 1
puts "FRONTENDTRIGGER_PIN_END FrontendTrigger ok=$::FRONTENDTRIGGER_PIN_OK bad=$::FRONTENDTRIGGER_PIN_BAD"
if {$::FRONTENDTRIGGER_PIN_BAD != 0} { error "FRONTENDTRIGGER_PIN_MISS=$::FRONTENDTRIGGER_PIN_BAD" }
if {$::FRONTENDTRIGGER_PIN_OK != 296} { error "FRONTENDTRIGGER_PIN_COUNT=$::FRONTENDTRIGGER_PIN_OK expect=296" }
