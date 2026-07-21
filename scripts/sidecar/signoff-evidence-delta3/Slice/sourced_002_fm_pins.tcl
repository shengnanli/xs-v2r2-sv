# Slice FM 钉点(FM 审计 2026-07)
# 0) 死网 BBPin(2026-07 复盘): 10 个 failing 全是 golden 子模块(两侧共享文件)内
#    未解析黑盒(queue/array)的死网引脚——两侧都悬空(如 _array_io_r_resp_data_0_data
#    [551:548] 无读者)。FM 默认 verification_set_undriven_signals=BINARY:X:
#    ref 悬空=自由割点、impl 悬空=X → 锥必失配(日志 Unmatched Cut REF=10/IMPL=0)。
#    设 BINARY 让两侧悬空信号按同名配对为同一自由变量(BankedDataArray 同法)。
setup
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} {
  puts "SLICE_PINS: undriven failed: $msg"
}
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
