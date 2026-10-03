# VIMac64b FM「匹配前」钉点（手写，12 位，fail-closed）
#
# 只钉 uopIdx 的两级打拍寄存器（6 位 x 2）。它们的 [5:1] 两侧都是没人读的死位：
# FM 默认不给 unread 点配对（report_unmatched_points -status unread 列出 ref 10 / impl 10），
# 于是 vmucp（verification_verify_matched_unread_compare_points）对它们不起作用 ——
# 2026-10-02 正式跑 @76a7067b 实测：appvar 已为 true，passing 仍是 911、unread 仍是 10 对。
# 钉上之后它们成为 matched 点，vmucp 才真的去比（依据与六条证据见 verif/fm_target_config/VIMac64b.tcl）。
# 整个寄存器 6 位一起钉（bit0 本来就能自动配上），不挑位。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数 != 12 即 error。进 fm.log 的输出一律 ASCII。
set ::VIMAC_PIN_EXPECT 12
set ::VIMAC_PIN_OK 0
set ::VIMAC_PIN_BAD 0
proc vimac_pin {g i} {
  if {[set_user_match "r:/WORK/VIMac64b/$g" "i:/WORK/VIMac64b/u_core/$i"]} {
    incr ::VIMAC_PIN_OK
  } else {
    incr ::VIMAC_PIN_BAD
    puts "VIMAC_PIN_FAIL: $g <-> $i"
  }
}
puts "VIMAC_PIN_BEGIN VIMac64b expect=$::VIMAC_PIN_EXPECT"
for {set b 0} {$b < 6} {incr b} {
  vimac_pin "uopIdxS1_reg\[$b\]" "uop_idx_s1_reg\[$b\]"
  vimac_pin "uopIdxS2_reg\[$b\]" "uop_idx_s2_reg\[$b\]"
}
puts "VIMAC_PIN_END VIMac64b ok=$::VIMAC_PIN_OK bad=$::VIMAC_PIN_BAD"
if {$::VIMAC_PIN_BAD != 0} { error "VIMAC_PIN_MISS=$::VIMAC_PIN_BAD" }
if {$::VIMAC_PIN_OK != 12} { error "VIMAC_PIN_COUNT=$::VIMAC_PIN_OK expect=12" }
