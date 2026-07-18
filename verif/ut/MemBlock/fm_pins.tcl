# MemBlock FM 钉点(FM 审计 2026-07)
# 8 路 perf 2 级打拍:golden inner_io_perf_<n>_value_REG(第1拍)/REG_1(第2拍) ↔
# 手写核 perf_stage1[n]/perf_stage2[n](FM 名 perf_stage1_reg[n][b]/perf_stage2_reg[n][b])。
# 历史 unmatched: ref inner_io_perf_1_value_REG vs impl perf_stage2_reg[2] 残留错位 —— 按名钉死。
set _n 0
for {set k 0} {$k < 8} {incr k} {
  for {set b 0} {$b < 6} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/inner_io_perf_${k}_value_REG_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_stage1_reg\[$k\]\[$b\]"}]} { incr _n }
    if {![catch {set_user_match "r:/WORK/$top/inner_io_perf_${k}_value_REG_1_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_stage2_reg\[$k\]\[$b\]"}]} { incr _n }
  }
}
puts "MEMBLOCK_PINS: perf $_n points pinned"
