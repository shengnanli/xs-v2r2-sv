# IBuffer FM 钉点(依据 unmatched_full.rpt):
#   ref enqPtrVec_N_value_reg[b] ↔ impl u_core/enqPtrVec_value_reg[N][b]
#     (16 个入队指针计数器; 展平名 value 位置不同: N_value_b vs value_N_b,
#      auto_match 的键规约对不上 → 显式钉)
#   ref topdown_stage_reasons_N_reg ↔ impl u_core/topdown_stage_reg[N] (N=10,12)
set _n 0; set _f 0
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)"; incr ::_f } else { incr ::_n }
}
for {set n 0} {$n < 16} {incr n} {
  for {set b 0} {$b < 3} {incr b} {
    _pin "r:/WORK/$top/enqPtrVec_${n}_value_reg\[$b\]" "i:/WORK/$top/u_core/enqPtrVec_value_reg\[$n\]\[$b\]"
  }
}
# topdown_stage 38 位全部尝试钉(已自动配对的 set_user_match 会失败, catch 吞掉即可;
# 不同轮次签名分析漏配的位不固定: 首轮 10/12, 次轮 4)
for {set n 0} {$n < 38} {incr n} {
  catch {undo_match "r:/WORK/$top/topdown_stage_reasons_${n}_reg"}
  catch {undo_match "i:/WORK/$top/u_core/topdown_stage_reg\[$n\]"}
  _pin "r:/WORK/$top/topdown_stage_reasons_${n}_reg" "i:/WORK/$top/u_core/topdown_stage_reg\[$n\]"
}
puts "IBUFFER_PINS: $_n pinned, $_f failed"
