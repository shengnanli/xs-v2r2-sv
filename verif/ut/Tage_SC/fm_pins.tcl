# Tage_SC FM 钉点(依据 unmatched_full.rpt):
#   mbistPl BBPin 两侧同名同模块但未自动配对 → 按名钉。
#   bankTickCtrs_N ↔ bank_tick_ctr[N]; bankTickCtrDistanceToTops_N ↔ bank_tick_dist[N];
#   scThresholds_N_ctr ↔ sc_thr_ctr[N]; scThresholds_N_thres ↔ sc_thr_thres[N]。
#   先整族 undo 清交叉错配再钉。
set _n 0; set _f 0
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)"; incr ::_f } else { incr ::_n }
}
# mbist 管道 BBPin
catch {undo_match "r:/WORK/$top/mbistPl/mbist_ack"}
catch {undo_match "i:/WORK/$top/mbistPl/mbist_ack"}
_pin "r:/WORK/$top/mbistPl/mbist_ack" "i:/WORK/$top/mbistPl/mbist_ack"
for {set b 0} {$b < 24} {incr b} {
  catch {undo_match "r:/WORK/$top/mbistPl/mbist_outdata\[$b\]"}
  catch {undo_match "i:/WORK/$top/mbistPl/mbist_outdata\[$b\]"}
  _pin "r:/WORK/$top/mbistPl/mbist_outdata\[$b\]" "i:/WORK/$top/mbistPl/mbist_outdata\[$b\]"
}
# tick 计数器/距离 (7 位), 阈值计数器(5)与阈值(8), 两个 bank
for {set n 0} {$n < 2} {incr n} {
  for {set b 0} {$b < 7} {incr b} {
    catch {undo_match "r:/WORK/$top/bankTickCtrs_${n}_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/bank_tick_ctr_reg\[$n\]\[$b\]"}
    _pin "r:/WORK/$top/bankTickCtrs_${n}_reg\[$b\]" "i:/WORK/$top/u_core/bank_tick_ctr_reg\[$n\]\[$b\]"
    catch {undo_match "r:/WORK/$top/bankTickCtrDistanceToTops_${n}_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/bank_tick_dist_reg\[$n\]\[$b\]"}
    _pin "r:/WORK/$top/bankTickCtrDistanceToTops_${n}_reg\[$b\]" "i:/WORK/$top/u_core/bank_tick_dist_reg\[$n\]\[$b\]"
  }
  for {set b 0} {$b < 5} {incr b} {
    catch {undo_match "r:/WORK/$top/scThresholds_${n}_ctr_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/sc_thr_ctr_reg\[$n\]\[$b\]"}
    _pin "r:/WORK/$top/scThresholds_${n}_ctr_reg\[$b\]" "i:/WORK/$top/u_core/sc_thr_ctr_reg\[$n\]\[$b\]"
  }
  for {set b 0} {$b < 8} {incr b} {
    catch {undo_match "r:/WORK/$top/scThresholds_${n}_thres_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/sc_thr_thres_reg\[$n\]\[$b\]"}
    _pin "r:/WORK/$top/scThresholds_${n}_thres_reg\[$b\]" "i:/WORK/$top/u_core/sc_thr_thres_reg\[$n\]\[$b\]"
  }
}
puts "TAGE_PINS: $_n pinned, $_f failed"
