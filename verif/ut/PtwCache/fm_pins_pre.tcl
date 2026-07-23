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
# 注: 早期版本曾用 `set_app_var verification_assume_reg_init none` 修 gated-clock l0/l1 SRAM
#     ram_reg 失配, 但实测(当前 RTL/wrapper)在默认 assume_reg_init=auto 下 SRAM ram_reg 已
#     0 失配(0 unmatched compare); 该 appvar 会进 relaxed_appvars → sidecar 判 strict_qualifications
#     PARTIAL, 故移除(与 ICacheDataArray 同: 无 assume_reg_init, relaxed_appvars=[])。
setup
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

# L2/L3 prefetch 流水链(对称死状态双射: golden 与 impl 结构同构, 仅命名不同; verify_matched_unread=true
# 下逐位比对相等——见 fm-strict-unread-methodology 修法④). golden 命名:
#   hitPre_r      = L3 DataHoldBypass 延迟保持  ↔ impl u_core/l3_hitPre_h_reg
#   hitPre_r_1    = L2 DataHoldBypass 延迟保持  ↔ impl u_core/l2_hitPre_h_reg
#   l3Pre_r       = L3 stageCheck 保持           ↔ impl u_core/l3Pre_reg
#   (l2Pre 同名自动配对, 无需 pin)
catch {undo_match "r:/WORK/$top/hitPre_r_reg"};   catch {undo_match "i:/WORK/$top/u_core/l3_hitPre_h_reg"}
catch {undo_match "r:/WORK/$top/hitPre_r_1_reg"}; catch {undo_match "i:/WORK/$top/u_core/l2_hitPre_h_reg"}
catch {undo_match "r:/WORK/$top/l3Pre_r_reg"};    catch {undo_match "i:/WORK/$top/u_core/l3Pre_reg"}
_pin "r:/WORK/$top/hitPre_r_reg"   "i:/WORK/$top/u_core/l3_hitPre_h_reg"
_pin "r:/WORK/$top/hitPre_r_1_reg" "i:/WORK/$top/u_core/l2_hitPre_h_reg"
_pin "r:/WORK/$top/l3Pre_r_reg"    "i:/WORK/$top/u_core/l3Pre_reg"

# L1 data_resp prefetch(delay 保持, 对称死): golden data_resp_r_{0,1}_entries_prefetch ↔ impl l1_data_resp_reg[{0,1}][prefetch]
for {set w 0} {$w < 2} {incr w} {
  catch {undo_match "r:/WORK/$top/data_resp_r_${w}_entries_prefetch_reg"}
  catch {undo_match "i:/WORK/$top/u_core/l1_data_resp_reg\[$w\]\\\[prefetch]"}
  _pin "r:/WORK/$top/data_resp_r_${w}_entries_prefetch_reg" "i:/WORK/$top/u_core/l1_data_resp_reg\[$w\]\\\[prefetch]"
}
puts "PTWCACHE_PINS: $_n pinned, $_f failed"
