# ICache FM 「匹配后」钉点 —— 自动生成：scripts/gen_icache_pins.py（勿手改；规则与理由见生成器文件头）
# 只 set_user_match 消名差：不约束 ref、不改 appvar、不加黑盒。逐条数返回值，拒一条或总数不等于字面常数即 error。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。
if {$top ne "ICache"} { error "ICACHE_POST_PIN_UNKNOWN_TOP=$top" }
set ::ICACHE_POST_EXPECT 53
set ::ICACHE_POST_OK 0
set ::ICACHE_POST_BAD 0
proc icache_post_pin {r i} {
  if {[set_user_match $r $i]} { incr ::ICACHE_POST_OK } else {
    incr ::ICACHE_POST_BAD
    if {$::ICACHE_POST_BAD <= 10} { puts "ICACHE_POST_PIN_FAIL: $r <-> $i" }
  }
}
puts "ICACHE_POST_PIN_BEGIN expect=$::ICACHE_POST_EXPECT"
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_0/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_0/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_1/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_1/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_2/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_2/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_3/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_3/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_4/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_4/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_5/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_5/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_6/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_6/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_0_7/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_0_7/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_0/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_0/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_1/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_1/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_2/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_2/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_3/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_3/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_4/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_4/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_5/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_5/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_6/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_6/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_1_7/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_1_7/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_0/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_0/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_1/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_1/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_2/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_2/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_3/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_3/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_4/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_4/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_5/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_5/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_6/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_6/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_2_7/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_2_7/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_0/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_0/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_1/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_1/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_2/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_2/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_3/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_3/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_4/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_4/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_5/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_5/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_6/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_6/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/dataArray/dataArrays_3_7/srams_0/rdata_hold_data_0_reg[65]} {i:/WORK/ICache/u_core/dataArray/dataArrays_3_7/srams_0/u_core/rdata_hold_reg[65]}
icache_post_pin {r:/WORK/ICache/missUnit/refill_done_r_counter_reg} {i:/WORK/ICache/u_core/missUnit/u_core/grant_beat_left_q_reg}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[53]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][48]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[54]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][49]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[55]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][50]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[56]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][51]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[57]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][52]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[58]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][53]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[59]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][54]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[60]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][55]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[61]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][56]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[62]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][57]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[63]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][58]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[64]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][59]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[65]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][60]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[66]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][61]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[67]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][62]}
icache_post_pin {r:/WORK/ICache/ctrlUnitOpt/out_back_q/ram_reg[68]} {i:/WORK/ICache/u_core/ctrlUnitOpt/out_back_q/slot_reg\[data][63]}
icache_post_pin {r:/WORK/ICache/dataArray/res/beReg_reg} {i:/WORK/ICache/u_core/dataArray/res/u_core/beReg_reg[0]}
icache_post_pin {r:/WORK/ICache/dataArray/res_1/beReg_reg} {i:/WORK/ICache/u_core/dataArray/res_1/u_core/beReg_reg[0]}
icache_post_pin {r:/WORK/ICache/dataArray/res_2/beReg_reg} {i:/WORK/ICache/u_core/dataArray/res_2/u_core/beReg_reg[0]}
icache_post_pin {r:/WORK/ICache/dataArray/res_3/beReg_reg} {i:/WORK/ICache/u_core/dataArray/res_3/u_core/beReg_reg[0]}
puts "ICACHE_POST_PIN_END ok=$::ICACHE_POST_OK bad=$::ICACHE_POST_BAD expect=$::ICACHE_POST_EXPECT"
if {$::ICACHE_POST_BAD != 0 || $::ICACHE_POST_OK != $::ICACHE_POST_EXPECT} {
  error "ICACHE_POST_PIN_COUNT ok=$::ICACHE_POST_OK bad=$::ICACHE_POST_BAD"
}
