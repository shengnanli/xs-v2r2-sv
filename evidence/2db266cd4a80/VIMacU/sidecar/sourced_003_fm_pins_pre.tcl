# =============================================================================
# fm_pins_pre.tcl —— VIMacU：两个 VIMac64b 实例内 uopIdx 两级打拍寄存器的精确钉配（2 实例 x 2 级 x 6 位 = 24 条）。
#
# 与 verif/ut/VIMac64b/fm_pins_pre.tcl 同一组寄存器、同一理由：golden 名 uopIdxS1/S2，重写件名 uop_idx_s1/s2，
# FM 不能按名配上；[5:1] 两侧都是没人读的对称死位（由 verif/fm_target_config/VIMacU.tcl 的 vmucp 实开比较），
# [0] 有读者。只在本层把实例路径加上，不新增任何其他配对。
# =============================================================================
set ::VIMACU_PIN_EXPECT 24
set ::VIMACU_PIN_OK 0
set ::VIMACU_PIN_BAD 0
proc vimacu_pin {inst g i} {
  if {[set_user_match "r:/WORK/VIMacU/$inst/$g" "i:/WORK/VIMacU/u_core/$inst/u_core/$i"]} {
    incr ::VIMACU_PIN_OK
  } else {
    incr ::VIMACU_PIN_BAD
    puts "VIMACU_PIN_FAIL: $inst $g <-> $i"
  }
}
puts "VIMACU_PIN_BEGIN VIMacU expect=$::VIMACU_PIN_EXPECT"
foreach inst {vimacs_0 vimacs_1} {
  for {set b 0} {$b < 6} {incr b} {
    vimacu_pin $inst "uopIdxS1_reg\[$b\]" "uop_idx_s1_reg\[$b\]"
    vimacu_pin $inst "uopIdxS2_reg\[$b\]" "uop_idx_s2_reg\[$b\]"
  }
}
puts "VIMACU_PIN_END VIMacU ok=$::VIMACU_PIN_OK bad=$::VIMACU_PIN_BAD"
if {$::VIMACU_PIN_BAD != 0} { error "VIMACU_PIN_MISS=$::VIMACU_PIN_BAD" }
if {$::VIMACU_PIN_OK != 24} { error "VIMACU_PIN_COUNT=$::VIMACU_PIN_OK expect=24" }
