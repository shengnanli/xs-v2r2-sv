# PtwCache FM 钉点(依据 unmatched_full.rpt):
#   ref state_reg_reg[0..14]   ↔ impl u_core/l3replace_reg[0..14]   (L3 PLRU 树)
#   ref state_reg_1_reg[0..14] ↔ impl u_core/l2replace_reg[0..14]   (L2 PLRU 树)
#   ref hitVec_N_reg           ↔ impl u_core/l3_hitVec_reg[N]       (L3 命中打拍)
#   ref hitVec_N_1_reg         ↔ impl u_core/l2_hitVec_reg[N]       (L2 命中打拍)
#   ref bypassed_N_valid_reg   ↔ impl u_core/stageCheck1_fire_1cycle_reg[N]
#     (golden 4 份 OneCycleValid 重复副本↔impl [3:0] 副本数组, 修法⑥;
#      旧 pin 误配到 stageDelay_bits_reg[0][bypassed][N] 常0载荷寄存器, 已纠正)
# 两侧部分位已被签名分析交叉配对(如 hitVec_0_1 与 l2_hitVec[11] 各自配错),
# 先整族 undo 再钉死。
# 0) FM 寄存器初值推断(Auto)把 impl 侧 ClockGate EN 约束成 LAT1X(ref 侧 LAT,
#    不对称)→gated-clock 的 l0/l1 SRAM ram_reg 全部失配; 关掉初值假设
#    (BankedDataArray/MainPipe 同法)。
setup
if {[catch {set_app_var verification_assume_reg_init none} msg]} {
  puts "PTWCACHE_PINS: assume_reg_init failed: $msg"
}
for {set b 0} {$b < 15} {incr b} {
  catch {undo_match "r:/WORK/$top/state_reg_reg\[$b\]"}
  catch {undo_match "r:/WORK/$top/state_reg_1_reg\[$b\]"}
  catch {undo_match "r:/WORK/$top/state_reg_4_reg\[$b\]"}
  catch {undo_match "i:/WORK/$top/u_core/l3replace_reg\[$b\]"}
  catch {undo_match "i:/WORK/$top/u_core/l2replace_reg\[$b\]"}
  catch {undo_match "i:/WORK/$top/u_core/spreplace_reg\[$b\]"}
}
for {set n 0} {$n < 16} {incr n} {
  catch {undo_match "r:/WORK/$top/hitVec_${n}_reg"}
  catch {undo_match "r:/WORK/$top/hitVec_${n}_1_reg"}
  catch {undo_match "r:/WORK/$top/hitVec_${n}_2_reg"}
  catch {undo_match "i:/WORK/$top/u_core/l3_hitVec_reg\[$n\]"}
  catch {undo_match "i:/WORK/$top/u_core/l2_hitVec_reg\[$n\]"}
  catch {undo_match "i:/WORK/$top/u_core/sp_hitVec_reg\[$n\]"}
}
for {set n 0} {$n < 4} {incr n} {
  catch {undo_match "r:/WORK/$top/bypassed_${n}_valid_reg"}
  catch {undo_match "r:/WORK/$top/bypassed_${n}_valid_1_reg"}
  catch {undo_match "r:/WORK/$top/hptw_bypassed_${n}_valid_reg"}
  catch {undo_match "i:/WORK/$top/u_core/stageCheck1_fire_1cycle_reg\[$n\]"}
  catch {undo_match "i:/WORK/$top/u_core/bypassed_hold_reg\[$n\]"}
  catch {undo_match "i:/WORK/$top/u_core/hptw_bypassed_hold_reg\[$n\]"}
  catch {undo_match "i:/WORK/$top/u_core/stageDelay_bits_reg\[0\]\\\[bypassed]\[$n\]"}
}
set _n 0; set _f 0
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)"; incr ::_f } else { incr ::_n }
}
for {set b 0} {$b < 15} {incr b} {
  _pin "r:/WORK/$top/state_reg_reg\[$b\]"   "i:/WORK/$top/u_core/l3replace_reg\[$b\]"
  _pin "r:/WORK/$top/state_reg_1_reg\[$b\]" "i:/WORK/$top/u_core/l2replace_reg\[$b\]"
  _pin "r:/WORK/$top/state_reg_4_reg\[$b\]" "i:/WORK/$top/u_core/spreplace_reg\[$b\]"
}
for {set n 0} {$n < 16} {incr n} {
  _pin "r:/WORK/$top/hitVec_${n}_reg"   "i:/WORK/$top/u_core/l3_hitVec_reg\[$n\]"
  _pin "r:/WORK/$top/hitVec_${n}_1_reg" "i:/WORK/$top/u_core/l2_hitVec_reg\[$n\]"
  _pin "r:/WORK/$top/hitVec_${n}_2_reg" "i:/WORK/$top/u_core/sp_hitVec_reg\[$n\]"
}
for {set n 0} {$n < 4} {incr n} {
  _pin "r:/WORK/$top/bypassed_${n}_valid_reg"      "i:/WORK/$top/u_core/stageCheck1_fire_1cycle_reg\[$n\]"
  _pin "r:/WORK/$top/bypassed_${n}_valid_1_reg"    "i:/WORK/$top/u_core/bypassed_hold_reg\[$n\]"
  _pin "r:/WORK/$top/hptw_bypassed_${n}_valid_reg" "i:/WORK/$top/u_core/hptw_bypassed_hold_reg\[$n\]"
}
# L1 g 位延迟向量(golden gVec_delay ↔ impl l1gVec_delay; impl 原先误传常0未用此寄存器,
# 已修 RTL 使其进入 l1 命中 asid 旁路, 见 ptwcache_query.svh)
for {set b 0} {$b < 2} {incr b} {
  catch {undo_match "r:/WORK/$top/gVec_delay_reg\[$b\]"}
  catch {undo_match "i:/WORK/$top/u_core/l1gVec_delay_reg\[$b\]"}
  _pin "r:/WORK/$top/gVec_delay_reg\[$b\]" "i:/WORK/$top/u_core/l1gVec_delay_reg\[$b\]"
}
puts "PTWCACHE_PINS: $_n pinned, $_f failed"
