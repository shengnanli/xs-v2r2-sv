# Slice FM 钉点(FM 审计 2026-07, codex_0036 修正后):
# 边界现为 3+2 非 305 逻辑子(DataStorage/RequestBuffer/RXSNP/MSHRBuffer[_1])两侧
# elaborate + 13 绿 305 子 assembly 黑盒 + 厂商 array_18_ext 黑盒。故不再需要 legacy
# 的 verification_set_undriven_signals=BINARY(那是全黑盒轮次为死网 BBPin 加的放宽
# appvar, 会被 sidecar 判 relaxed→PARTIAL, 永达不到 SUCCEEDED)。已移除。
# perf 2 级打拍:golden io_perf_<n>_value_REG(第1拍)/REG_1(第2拍) ↔
# 手写核 perf_<n>_value_s1(第1拍)/s2(第2拍)。
# 2026-07 全貌重跑实证:签名配对把「拍」配反(REG_1↔s1, REG↔s2),12 路 perf 的
# 寄存器+输出端口共 40 点全因此 fail。按名逐位钉死正确的拍对应。
set _n 0
for {set k 0} {$k < 20} {incr k} {
  for {set b 0} {$b < 6} {incr b} {
    if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_${k}_value_s1_reg\[$b\]"}]} { incr _n }
    if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_1_reg\[$b\]" \
                                "i:/WORK/$top/u_core/perf_${k}_value_s2_reg\[$b\]"}]} { incr _n }
  }
  # 1-bit 通道可能无位下标
  if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_reg" \
                              "i:/WORK/$top/u_core/perf_${k}_value_s1_reg"}]} { incr _n }
  if {![catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_1_reg" \
                              "i:/WORK/$top/u_core/perf_${k}_value_s2_reg"}]} { incr _n }
}
puts "SLICE_PINS: perf $_n points pinned"
