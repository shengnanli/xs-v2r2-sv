# L2TLBWrapper FM 钉点(FM 审计 2026-07)
# 19 路 perf 2 级打拍:golden io_perf_<n>_value_REG(第1拍)/REG_1(第2拍) ↔
# 手写核 perf_pipe[n].stage[0]/stage[1](FM 名 perf_pipe_reg[n]\[stage][s][b])。
# 历史 unmatched: ref 全部 19 路第1拍寄存器 vs impl stage[0] —— 按名逐位钉死。
set _n 0
for {set k 0} {$k < 19} {incr k} {
  for {set b 0} {$b < 6} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_pipe_reg\[$k\]\\\[stage\]\[0\]\[$b\]"}]} { incr _n }
    if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_1_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_pipe_reg\[$k\]\\\[stage\]\[1\]\[$b\]"}]} { incr _n }
  }
}
puts "L2TLBWRAPPER_PINS: perf $_n points pinned"
