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

# --------------------------------------------------------------------------
# HPerfCounter_21 内 event_op_2 死位双射钉点（两侧同款 golden HPerfMonitor_3 →
# HPerfCounter_21 elaborate）：
#   golden HPerfCounter_21 里 event_op_2 / event_op_2_reg 是 5 位 reg（[4:0]），但只读
#   [0:2]（一个优先 mux, 见 golden L387-391），bit[3]/[4] cone-dead（写了从不读）。
#   FM 对「两侧都死」的寄存器不自动配对 → 8 个 HPerfCounter_21 实例
#   (perfEvents_hpc, _1..._7) × {event_op_2_reg, event_op_2_reg_reg} × bit{3,4}
#   = 8×2×2 = 32 点，两侧同名同路径（仅差 u_core/ 前缀），是完美对称双射。
#   逐点 set_user_match 配对 → 成 matched-unread；runner vmucp=true 下 FM 逐位实比证等价
#   → 转 passing（真等价非 vacuous）。(同 NewCSR 的 HPerfMonitor event_op_2 死位处理。)
# --------------------------------------------------------------------------
set _hpc {perfEvents_hpc perfEvents_hpc_1 perfEvents_hpc_2 perfEvents_hpc_3 \
          perfEvents_hpc_4 perfEvents_hpc_5 perfEvents_hpc_6 perfEvents_hpc_7}
set _m 0
foreach _c $_hpc {
  foreach _r {event_op_2_reg event_op_2_reg_reg} {
    foreach _b {3 4} {
      set _rp "r:/WORK/$top/inner_perfEvents_hpm/$_c/${_r}\[$_b\]"
      set _ip "i:/WORK/$top/u_core/inner_perfEvents_hpm/$_c/${_r}\[$_b\]"
      if {![catch {set_user_match $_rp $_ip}]} { incr _m }
    }
  }
}
puts "MEMBLOCK_PINS: hpc event_op_2 dead-bit $_m points pinned"
