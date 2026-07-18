# TL2CHICoupledL2 FM 钉点(FM 审计 2026-07, v2)
# perf 2 级打拍寄存器:golden io_perf_<n>_value_REG(第1拍)/REG_1(第2拍) ↔
# 手写核 perfStage1[n]/perfStage2[n]。
# 全貌重跑实证 FM 展平名为 perfStage1_reg[n][b](2维下标),签名配对把拍/路交叉配错
# (io_perf_1_REG_1↔perfStage1[1], io_perf_2_REG_1↔perfStage2[1]),36 failing 中 24
# 因此而来。按名逐位钉死;两种展平名各试一次(不同版本 FM 命名有差)。
set _n 0
for {set k 1} {$k <= 48} {incr k} {
  for {set b 0} {$b < 6} {incr b} {
    set r1 "r:/WORK/$top/io_perf_${k}_value_REG_reg\[$b\]"
    set r2 "r:/WORK/$top/io_perf_${k}_value_REG_1_reg\[$b\]"
    foreach i1 [list "i:/WORK/$top/u_core/perfStage1_reg\[$k\]\[$b\]" \
                     "i:/WORK/$top/u_core/perfStage1_${k}_reg\[$b\]"] {
      if {![catch {set_user_match $r1 $i1}]} { incr _n; break }
    }
    foreach i2 [list "i:/WORK/$top/u_core/perfStage2_reg\[$k\]\[$b\]" \
                     "i:/WORK/$top/u_core/perfStage2_${k}_reg\[$b\]"] {
      if {![catch {set_user_match $r2 $i2}]} { incr _n; break }
    }
  }
}
puts "TL2CHI_PINS: perf $_n points pinned"
