# =============================================================================
# fm_pins_pre.tcl —— VecExcpDataMergeModule「匹配前」钉点（只 set_user_match，不约束 ref）
#
# 要消的名差：golden 把 Vec 寄存器平铺成 <名>_<k>[_字段]，重写核在 u_core 下用数组
#   <名>[k]（FM 单元名 u_core/<名>_reg[k][b]）；sWaitRab_vecExcpInfo 的三个残留字段在核里
#   叫 sWaitRab_nf / _isStride / _isWhole；写 valid 打拍叫 w_valid_q[k]。
# 范围：golden 顶层全部寄存器 = 750 位（逐条列在下面）。child（GetE8OffsetInVreg /
#   NfMappedElemIdx 纯组合；DelayN_13 1 位）内部不钉，交给 FM 自动配对。
# fail-closed：set_user_match 不抛异常，逐条数返回值；拒一条或总数 != 750 即 error。
# 进 fm.log 的输出全 ASCII。
# =============================================================================
set ::VEM_PIN_EXPECT 750
set ::VEM_PIN_OK 0
set ::VEM_PIN_BAD 0
proc vem_pin {g i w} {
  set top VecExcpDataMergeModule
  if {$w == 1} {
    set pairs [list "r:/WORK/$top/${g}_reg" "i:/WORK/$top/u_core/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/$top/${g}_reg\[$b\]" "i:/WORK/$top/u_core/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::VEM_PIN_OK } else {
      incr ::VEM_PIN_BAD
      if {$::VEM_PIN_BAD <= 10} { puts "VEM_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "VEM_PIN_BEGIN VecExcpDataMergeModule expect=$::VEM_PIN_EXPECT"
# 记账位 4 x 8 = 32
foreach n {commitNeeded rabCommitted ratCommitted hasReadRf} {
  for {set k 0} {$k < 8} {incr k} { vem_pin ${n}_$k ${n}_reg\[$k\] 1 }
}
# 映射表 8 x (6 + 7 + 7) = 160
for {set k 0} {$k < 8} {incr k} {
  vem_pin regMaps_${k}_lreg    regMaps_lreg_reg\[$k\]    6
  vem_pin regMaps_${k}_newPreg regMaps_newPreg_reg\[$k\] 7
  vem_pin regMaps_${k}_oldPreg regMaps_oldPreg_reg\[$k\] 7
}
# 拼好的数据 4 x 128 = 512，写 valid 打拍 4
for {set k 0} {$k < 4} {incr k} {
  vem_pin mergedVd_${k}_rawData mergedVd_reg\[$k\] 128
  vem_pin o_toVPRF_w_${k}_valid_REG w_valid_q_reg\[$k\] 1
}
# 状态与 currentIdx 3 + 4 = 7
vem_pin state      state_reg      3
vem_pin currentIdx currentIdx_reg 4
# sWaitRab_* 35
vem_pin sWaitRab_vecExcpInfo_next_bits_r_nf       sWaitRab_nf_reg       3
vem_pin sWaitRab_vecExcpInfo_next_bits_r_isStride sWaitRab_isStride_reg 1
vem_pin sWaitRab_vecExcpInfo_next_bits_r_isWhole  sWaitRab_isWhole_reg  1
vem_pin sWaitRab_useNewVdUntil      sWaitRab_useNewVdUntil_reg      3
vem_pin sWaitRab_needMergeUntil     sWaitRab_needMergeUntil_reg     4
vem_pin sWaitRab_e8offset           sWaitRab_e8offset_reg           4
vem_pin sWaitRab_handleUntil        sWaitRab_handleUntil_reg        4
vem_pin sWaitRab_nonSegIndexed      sWaitRab_nonSegIndexed_reg      1
for {set n 0} {$n < 4} {incr n} { vem_pin sWaitRab_vemul_i_d_$n sWaitRab_vemul_i_d_reg\[$n\] 1 }
vem_pin sWaitRab_dvemulNoLessThanM1 sWaitRab_dvemulNoLessThanM1_reg 2
vem_pin sWaitRab_rabWriteOffset     sWaitRab_rabWriteOffset_reg     4
vem_pin sWaitRab_ratWriteOffset     sWaitRab_ratWriteOffset_reg     4
puts "VEM_PIN_END VecExcpDataMergeModule ok=$::VEM_PIN_OK bad=$::VEM_PIN_BAD"
if {$::VEM_PIN_BAD != 0} { error "VEM_PIN_MISS=$::VEM_PIN_BAD" }
if {$::VEM_PIN_OK != 750} { error "VEM_PIN_COUNT=$::VEM_PIN_OK expect=750" }
