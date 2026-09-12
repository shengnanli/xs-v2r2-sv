# ICacheCtrlUnit FM 钉点 (FM 审计 2026-07)
# --------------------------------------------------------------------------
# out_back_q = Queue1_RegMapperInput_3 (RegMapper 输出背压队列)。RegMapper 的通用
# data 字段宽 64 位, 但 ICacheCtrlUnit 只消费 data[47:0](ECC 控制字/ecciaddr paddr)
# 加若干低控制位; data[63:48] 这 16 位存入队列却从不被父级读出 —— 在 golden 与手写核
# 里都是死位 (bug-for-bug 一致)。
#   golden : 队列存储打包成 ram_reg, data[48+k] 落在绝对位 ram_reg[53+k] (k=0..15)
#   手写核 : 用可读 struct slot (reg_req_t), FM 展平名 slot_reg\[data][48+k]
# 词干不同 (ram_reg vs slot_reg[data]) 令 auto_match_flattened_arrays 无法配对
# → 16 (ref) + 16 (impl) unmatched-unread。二者是严格 16↔16 双射: 同为 queue entry
# 的 data 位 48+k, 同源 io_enq_bits_data[48+k] 锁存。按名逐位 set_user_match。
# 仅消名差, 不约束 ref, 不 dont_verify, 不扩黑盒 (符合 reviewer ICache 裁定第 1 条)。
# 对 Queue1_RegMapperInput_3 变体 (out_back_q 即为 top、data 位是输出端口不死),
# 下列路径不存在 → set_user_match 抛错被 catch 吞掉, 无副作用。
# --------------------------------------------------------------------------
set _n 0
for {set k 0} {$k < 16} {incr k} {
  set br [expr {53 + $k}]
  set bi [expr {48 + $k}]
  if {![catch {set_user_match "r:/WORK/$top/out_back_q/ram_reg\[$br\]" \
                              "i:/WORK/$top/out_back_q/slot_reg\\\[data\]\[$bi\]"}]} { incr _n }
}
puts "ICACHECTRLUNIT_PINS: out_back_q dead data\[63:48\] $_n / 16 points pinned"
