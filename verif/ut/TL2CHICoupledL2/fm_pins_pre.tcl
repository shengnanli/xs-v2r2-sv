# TL2CHICoupledL2 FM「匹配前」钉点（本层异名寄存器，静态）—— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）
#
# 内容 = TL2CHICoupledL2 本层（xs_TL2CHICoupledL2_core）与 golden 异名的寄存器 841 位；child（slices_0..3 / prefetcher / pCrdQueue_s2）是 green_child 黑盒（codex 0217），内部不配对。
# set_user_match 只声明两点对应，比较照比。fail-closed：逐条数返回值；拒一条或总数 != 842 即 error。
set ::TL2_PIN_OK 0
set ::TL2_PIN_BAD 0
proc tl2_pin {r i} {
  if {[set_user_match "r:/WORK/TL2CHICoupledL2/$r" "i:/WORK/TL2CHICoupledL2/$i"]} { incr ::TL2_PIN_OK } else {
    incr ::TL2_PIN_BAD
    if {$::TL2_PIN_BAD <= 10} { puts "TL2_PIN_FAIL: $r <-> $i" }
  }
}
proc tl2_pinw {r i w} {
  for {set b 0} {$b < $w} {incr b} { tl2_pin "${r}\[$b\]" "${i}\[$b\]" }
}
puts "TL2_PIN_BEGIN TL2CHICoupledL2 expect=842"
tl2_pin {allCanFire_REG_reg} {u_core/noHint2_d1_reg}
tl2_pin {allCanFire_REG_1_reg} {u_core/noHint2_d2_reg}
tl2_pin {allCanFire_REG_2_reg} {u_core/noHint3_d1_reg}
tl2_pin {allCanFire_REG_3_reg} {u_core/noHint3_d2_reg}
tl2_pin {allCanFire_REG_4_reg} {u_core/noHint3_d3_reg}
tl2_pin {sliceCanFire_REG_reg} {u_core/pick2_d1_reg[0]}
tl2_pin {sliceCanFire_REG_1_reg} {u_core/pick2_d2_reg[0]}
tl2_pin {sliceCanFire_REG_2_reg} {u_core/pick3_d1_reg[0]}
tl2_pin {sliceCanFire_REG_3_reg} {u_core/pick3_d2_reg[0]}
tl2_pin {sliceCanFire_REG_4_reg} {u_core/pick3_d3_reg[0]}
tl2_pin {sliceCanFire_REG_5_reg} {u_core/pick2_d1_reg[1]}
tl2_pin {sliceCanFire_REG_6_reg} {u_core/pick2_d2_reg[1]}
tl2_pin {sliceCanFire_REG_7_reg} {u_core/pick3_d1_reg[1]}
tl2_pin {sliceCanFire_REG_8_reg} {u_core/pick3_d2_reg[1]}
tl2_pin {sliceCanFire_REG_9_reg} {u_core/pick3_d3_reg[1]}
tl2_pin {sliceCanFire_REG_10_reg} {u_core/pick2_d1_reg[2]}
tl2_pin {sliceCanFire_REG_11_reg} {u_core/pick2_d2_reg[2]}
tl2_pin {sliceCanFire_REG_12_reg} {u_core/pick3_d1_reg[2]}
tl2_pin {sliceCanFire_REG_13_reg} {u_core/pick3_d2_reg[2]}
tl2_pin {sliceCanFire_REG_14_reg} {u_core/pick3_d3_reg[2]}
tl2_pin {sliceCanFire_REG_15_reg} {u_core/pick2_d1_reg[3]}
tl2_pin {sliceCanFire_REG_16_reg} {u_core/pick2_d2_reg[3]}
tl2_pin {sliceCanFire_REG_17_reg} {u_core/pick3_d1_reg[3]}
tl2_pin {sliceCanFire_REG_18_reg} {u_core/pick3_d2_reg[3]}
tl2_pin {sliceCanFire_REG_19_reg} {u_core/pick3_d3_reg[3]}
tl2_pinw {io_perf_1_value_REG_reg} {u_core/perf_d1_reg[0]} 6
tl2_pinw {io_perf_1_value_REG_1_reg} {u_core/perf_d2_reg[0]} 6
tl2_pinw {io_perf_2_value_REG_reg} {u_core/perf_d1_reg[1]} 6
tl2_pinw {io_perf_2_value_REG_1_reg} {u_core/perf_d2_reg[1]} 6
tl2_pinw {io_perf_3_value_REG_reg} {u_core/perf_d1_reg[2]} 6
tl2_pinw {io_perf_3_value_REG_1_reg} {u_core/perf_d2_reg[2]} 6
tl2_pinw {io_perf_4_value_REG_reg} {u_core/perf_d1_reg[3]} 6
tl2_pinw {io_perf_4_value_REG_1_reg} {u_core/perf_d2_reg[3]} 6
tl2_pinw {io_perf_5_value_REG_reg} {u_core/perf_d1_reg[4]} 6
tl2_pinw {io_perf_5_value_REG_1_reg} {u_core/perf_d2_reg[4]} 6
tl2_pinw {io_perf_6_value_REG_reg} {u_core/perf_d1_reg[5]} 6
tl2_pinw {io_perf_6_value_REG_1_reg} {u_core/perf_d2_reg[5]} 6
tl2_pinw {io_perf_7_value_REG_reg} {u_core/perf_d1_reg[6]} 6
tl2_pinw {io_perf_7_value_REG_1_reg} {u_core/perf_d2_reg[6]} 6
tl2_pinw {io_perf_8_value_REG_reg} {u_core/perf_d1_reg[7]} 6
tl2_pinw {io_perf_8_value_REG_1_reg} {u_core/perf_d2_reg[7]} 6
tl2_pinw {io_perf_9_value_REG_reg} {u_core/perf_d1_reg[8]} 6
tl2_pinw {io_perf_9_value_REG_1_reg} {u_core/perf_d2_reg[8]} 6
tl2_pinw {io_perf_10_value_REG_reg} {u_core/perf_d1_reg[9]} 6
tl2_pinw {io_perf_10_value_REG_1_reg} {u_core/perf_d2_reg[9]} 6
tl2_pinw {io_perf_11_value_REG_reg} {u_core/perf_d1_reg[10]} 6
tl2_pinw {io_perf_11_value_REG_1_reg} {u_core/perf_d2_reg[10]} 6
tl2_pinw {io_perf_12_value_REG_reg} {u_core/perf_d1_reg[11]} 6
tl2_pinw {io_perf_12_value_REG_1_reg} {u_core/perf_d2_reg[11]} 6
tl2_pinw {io_perf_13_value_REG_reg} {u_core/perf_d1_reg[12]} 6
tl2_pinw {io_perf_13_value_REG_1_reg} {u_core/perf_d2_reg[12]} 6
tl2_pinw {io_perf_14_value_REG_reg} {u_core/perf_d1_reg[13]} 6
tl2_pinw {io_perf_14_value_REG_1_reg} {u_core/perf_d2_reg[13]} 6
tl2_pinw {io_perf_15_value_REG_reg} {u_core/perf_d1_reg[14]} 6
tl2_pinw {io_perf_15_value_REG_1_reg} {u_core/perf_d2_reg[14]} 6
tl2_pinw {io_perf_16_value_REG_reg} {u_core/perf_d1_reg[15]} 6
tl2_pinw {io_perf_16_value_REG_1_reg} {u_core/perf_d2_reg[15]} 6
tl2_pinw {io_perf_17_value_REG_reg} {u_core/perf_d1_reg[16]} 6
tl2_pinw {io_perf_17_value_REG_1_reg} {u_core/perf_d2_reg[16]} 6
tl2_pinw {io_perf_18_value_REG_reg} {u_core/perf_d1_reg[17]} 6
tl2_pinw {io_perf_18_value_REG_1_reg} {u_core/perf_d2_reg[17]} 6
tl2_pinw {io_perf_19_value_REG_reg} {u_core/perf_d1_reg[18]} 6
tl2_pinw {io_perf_19_value_REG_1_reg} {u_core/perf_d2_reg[18]} 6
tl2_pinw {io_perf_20_value_REG_reg} {u_core/perf_d1_reg[19]} 6
tl2_pinw {io_perf_20_value_REG_1_reg} {u_core/perf_d2_reg[19]} 6
tl2_pinw {io_perf_21_value_REG_reg} {u_core/perf_d1_reg[20]} 6
tl2_pinw {io_perf_21_value_REG_1_reg} {u_core/perf_d2_reg[20]} 6
tl2_pinw {io_perf_22_value_REG_reg} {u_core/perf_d1_reg[21]} 6
tl2_pinw {io_perf_22_value_REG_1_reg} {u_core/perf_d2_reg[21]} 6
tl2_pinw {io_perf_23_value_REG_reg} {u_core/perf_d1_reg[22]} 6
tl2_pinw {io_perf_23_value_REG_1_reg} {u_core/perf_d2_reg[22]} 6
tl2_pinw {io_perf_24_value_REG_reg} {u_core/perf_d1_reg[23]} 6
tl2_pinw {io_perf_24_value_REG_1_reg} {u_core/perf_d2_reg[23]} 6
tl2_pinw {io_perf_25_value_REG_reg} {u_core/perf_d1_reg[24]} 6
tl2_pinw {io_perf_25_value_REG_1_reg} {u_core/perf_d2_reg[24]} 6
tl2_pinw {io_perf_26_value_REG_reg} {u_core/perf_d1_reg[25]} 6
tl2_pinw {io_perf_26_value_REG_1_reg} {u_core/perf_d2_reg[25]} 6
tl2_pinw {io_perf_27_value_REG_reg} {u_core/perf_d1_reg[26]} 6
tl2_pinw {io_perf_27_value_REG_1_reg} {u_core/perf_d2_reg[26]} 6
tl2_pinw {io_perf_28_value_REG_reg} {u_core/perf_d1_reg[27]} 6
tl2_pinw {io_perf_28_value_REG_1_reg} {u_core/perf_d2_reg[27]} 6
tl2_pinw {io_perf_29_value_REG_reg} {u_core/perf_d1_reg[28]} 6
tl2_pinw {io_perf_29_value_REG_1_reg} {u_core/perf_d2_reg[28]} 6
tl2_pinw {io_perf_30_value_REG_reg} {u_core/perf_d1_reg[29]} 6
tl2_pinw {io_perf_30_value_REG_1_reg} {u_core/perf_d2_reg[29]} 6
tl2_pinw {io_perf_31_value_REG_reg} {u_core/perf_d1_reg[30]} 6
tl2_pinw {io_perf_31_value_REG_1_reg} {u_core/perf_d2_reg[30]} 6
tl2_pinw {io_perf_32_value_REG_reg} {u_core/perf_d1_reg[31]} 6
tl2_pinw {io_perf_32_value_REG_1_reg} {u_core/perf_d2_reg[31]} 6
tl2_pinw {io_perf_33_value_REG_reg} {u_core/perf_d1_reg[32]} 6
tl2_pinw {io_perf_33_value_REG_1_reg} {u_core/perf_d2_reg[32]} 6
tl2_pinw {io_perf_34_value_REG_reg} {u_core/perf_d1_reg[33]} 6
tl2_pinw {io_perf_34_value_REG_1_reg} {u_core/perf_d2_reg[33]} 6
tl2_pinw {io_perf_35_value_REG_reg} {u_core/perf_d1_reg[34]} 6
tl2_pinw {io_perf_35_value_REG_1_reg} {u_core/perf_d2_reg[34]} 6
tl2_pinw {io_perf_36_value_REG_reg} {u_core/perf_d1_reg[35]} 6
tl2_pinw {io_perf_36_value_REG_1_reg} {u_core/perf_d2_reg[35]} 6
tl2_pinw {io_perf_37_value_REG_reg} {u_core/perf_d1_reg[36]} 6
tl2_pinw {io_perf_37_value_REG_1_reg} {u_core/perf_d2_reg[36]} 6
tl2_pinw {io_perf_38_value_REG_reg} {u_core/perf_d1_reg[37]} 6
tl2_pinw {io_perf_38_value_REG_1_reg} {u_core/perf_d2_reg[37]} 6
tl2_pinw {io_perf_39_value_REG_reg} {u_core/perf_d1_reg[38]} 6
tl2_pinw {io_perf_39_value_REG_1_reg} {u_core/perf_d2_reg[38]} 6
tl2_pinw {io_perf_40_value_REG_reg} {u_core/perf_d1_reg[39]} 6
tl2_pinw {io_perf_40_value_REG_1_reg} {u_core/perf_d2_reg[39]} 6
tl2_pinw {io_perf_41_value_REG_reg} {u_core/perf_d1_reg[40]} 6
tl2_pinw {io_perf_41_value_REG_1_reg} {u_core/perf_d2_reg[40]} 6
tl2_pinw {io_perf_42_value_REG_reg} {u_core/perf_d1_reg[41]} 6
tl2_pinw {io_perf_42_value_REG_1_reg} {u_core/perf_d2_reg[41]} 6
tl2_pinw {io_perf_43_value_REG_reg} {u_core/perf_d1_reg[42]} 6
tl2_pinw {io_perf_43_value_REG_1_reg} {u_core/perf_d2_reg[42]} 6
tl2_pinw {io_perf_44_value_REG_reg} {u_core/perf_d1_reg[43]} 6
tl2_pinw {io_perf_44_value_REG_1_reg} {u_core/perf_d2_reg[43]} 6
tl2_pinw {io_perf_45_value_REG_reg} {u_core/perf_d1_reg[44]} 6
tl2_pinw {io_perf_45_value_REG_1_reg} {u_core/perf_d2_reg[44]} 6
tl2_pinw {io_perf_46_value_REG_reg} {u_core/perf_d1_reg[45]} 6
tl2_pinw {io_perf_46_value_REG_1_reg} {u_core/perf_d2_reg[45]} 6
tl2_pinw {io_perf_47_value_REG_reg} {u_core/perf_d1_reg[46]} 6
tl2_pinw {io_perf_47_value_REG_1_reg} {u_core/perf_d2_reg[46]} 6
tl2_pinw {io_perf_48_value_REG_reg} {u_core/perf_d1_reg[47]} 6
tl2_pinw {io_perf_48_value_REG_1_reg} {u_core/perf_d2_reg[47]} 6
tl2_pinw {io_perf_49_value_REG_reg} {u_core/perf_d1_reg[48]} 6
tl2_pinw {io_perf_49_value_REG_1_reg} {u_core/perf_d2_reg[48]} 6
tl2_pinw {io_perf_50_value_REG_reg} {u_core/perf_d1_reg[49]} 6
tl2_pinw {io_perf_50_value_REG_1_reg} {u_core/perf_d2_reg[49]} 6
tl2_pinw {io_perf_51_value_REG_reg} {u_core/perf_d1_reg[50]} 6
tl2_pinw {io_perf_51_value_REG_1_reg} {u_core/perf_d2_reg[50]} 6
tl2_pinw {io_perf_52_value_REG_reg} {u_core/perf_d1_reg[51]} 6
tl2_pinw {io_perf_52_value_REG_1_reg} {u_core/perf_d2_reg[51]} 6
tl2_pinw {io_perf_53_value_REG_reg} {u_core/perf_d1_reg[52]} 6
tl2_pinw {io_perf_53_value_REG_1_reg} {u_core/perf_d2_reg[52]} 6
tl2_pinw {io_perf_54_value_REG_reg} {u_core/perf_d1_reg[53]} 6
tl2_pinw {io_perf_54_value_REG_1_reg} {u_core/perf_d2_reg[53]} 6
tl2_pinw {io_perf_55_value_REG_reg} {u_core/perf_d1_reg[54]} 6
tl2_pinw {io_perf_55_value_REG_1_reg} {u_core/perf_d2_reg[54]} 6
tl2_pinw {io_perf_56_value_REG_reg} {u_core/perf_d1_reg[55]} 6
tl2_pinw {io_perf_56_value_REG_1_reg} {u_core/perf_d2_reg[55]} 6
tl2_pinw {io_perf_57_value_REG_reg} {u_core/perf_d1_reg[56]} 6
tl2_pinw {io_perf_57_value_REG_1_reg} {u_core/perf_d2_reg[56]} 6
tl2_pinw {io_perf_58_value_REG_reg} {u_core/perf_d1_reg[57]} 6
tl2_pinw {io_perf_58_value_REG_1_reg} {u_core/perf_d2_reg[57]} 6
tl2_pinw {io_perf_59_value_REG_reg} {u_core/perf_d1_reg[58]} 6
tl2_pinw {io_perf_59_value_REG_1_reg} {u_core/perf_d2_reg[58]} 6
tl2_pinw {io_perf_60_value_REG_reg} {u_core/perf_d1_reg[59]} 6
tl2_pinw {io_perf_60_value_REG_1_reg} {u_core/perf_d2_reg[59]} 6
tl2_pinw {io_perf_61_value_REG_reg} {u_core/perf_d1_reg[60]} 6
tl2_pinw {io_perf_61_value_REG_1_reg} {u_core/perf_d2_reg[60]} 6
tl2_pinw {io_perf_62_value_REG_reg} {u_core/perf_d1_reg[61]} 6
tl2_pinw {io_perf_62_value_REG_1_reg} {u_core/perf_d2_reg[61]} 6
tl2_pinw {io_perf_63_value_REG_reg} {u_core/perf_d1_reg[62]} 6
tl2_pinw {io_perf_63_value_REG_1_reg} {u_core/perf_d2_reg[62]} 6
tl2_pinw {io_perf_64_value_REG_reg} {u_core/perf_d1_reg[63]} 6
tl2_pinw {io_perf_64_value_REG_1_reg} {u_core/perf_d2_reg[63]} 6
tl2_pinw {io_perf_65_value_REG_reg} {u_core/perf_d1_reg[64]} 6
tl2_pinw {io_perf_65_value_REG_1_reg} {u_core/perf_d2_reg[64]} 6
tl2_pinw {io_perf_66_value_REG_reg} {u_core/perf_d1_reg[65]} 6
tl2_pinw {io_perf_66_value_REG_1_reg} {u_core/perf_d2_reg[65]} 6
tl2_pinw {io_perf_67_value_REG_reg} {u_core/perf_d1_reg[66]} 6
tl2_pinw {io_perf_67_value_REG_1_reg} {u_core/perf_d2_reg[66]} 6
tl2_pinw {io_perf_68_value_REG_reg} {u_core/perf_d1_reg[67]} 6
tl2_pinw {io_perf_68_value_REG_1_reg} {u_core/perf_d2_reg[67]} 6
tl2_pin {txdat_arb/pendingMask_reg[0]} {txdat_arb/u_arbiter/pendingMask_reg[0]}
puts "TL2_PIN_END TL2CHICoupledL2 ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD"
if {$::TL2_PIN_BAD != 0 || $::TL2_PIN_OK != 842} {
  error "TL2_PIN_MISMATCH ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD expect=842"
}
