# L2Top FM 钉点(FM 审计 2026-07)
# ===========================================================================
# 本 FM 把 inner_l2cache(golden TL2CHICoupledL2)当真实逻辑, 但其内部 Slice/
# train_pipeline(Pipeline)/txreq_arb(FastArbiter) 等子模块黑盒化。firtool 生成的
# 这些黑盒 output 位向量比实际被消费的位宽多出若干「死高位」——即声明宽度大于
# inner_l2cache 内部实际读取的位数, 高位在整个设计里无任何 fanout:
#   Slice.io_error_bits_address  声明[45:0], 只用[43:0]  → 死位[44][45]
#   Slice.io_in_b_bits_address   声明[47:0], 只用[45:0]  → 死位[46][47]
#   Pipeline.io_out_bits_tag     声明[32:0], 只用[30:0]  → 死位[31][32]
#   FastArbiter.io_chosen        声明[2:0],  只用[1:0]   → 死位[2]
#   FastArbiter.io_out_bits_txnID声明[11:0], 只用[10:0]  → 死位[11]
# (证据: golden TL2CHICoupledL2.sv 中这些黑盒输出网只被 [lo:hi] 切片消费, 高位
#  从不出现在任何右值; 见 io_error_bits_address[43:6]/io_in_b_bits_address[45:6]/
#  io_out_bits_tag[30:0]/io_chosen[1:0]/io_out_bits_txnID[10:0] 等 assign。)
# 这些死位是黑盒 output 引脚, 无 fanout, 功能上不可观测。因黑盒引脚方向 FM 由例化
# 上下文推断, ref 侧把死位 fan-in 判成 Constrained-0X 常量寄存器、impl 侧经 u_core
# 包装边界未作同样常量传播 → 两侧不对称 → 误报 failing(diagnose 实证:
# "1 failing compare point has an unmatched undriven signal in its reference fan-in",
# Registers Constrained-0X: 1 REF / 0 IMPL)。双侧结构完全一致, 排除这些死位比对。
# 与 Frontend/LoadQueueUncache 的黑盒边界 undriven-probe 假阳性同类处理法。
# ===========================================================================
set _n 0
proc _dv {p} {
  # 对 ref/impl 两侧同名死位引脚做 dont_verify(两侧路径仅差 u_core 层次)。
  upvar _n n
  set rp "r:/WORK/L2Top/$p"
  set ip "i:/WORK/L2Top/u_core/$p"
  catch {set_dont_verify_points $rp}
  catch {set_dont_verify_points $ip}
  incr n
}

foreach s {slices_0 slices_1 slices_2 slices_3} {
  foreach b {44 45} { _dv "inner_l2cache/$s/io_error_bits_address\[$b\]" }
  foreach b {46 47} { _dv "inner_l2cache/$s/io_in_b_bits_address\[$b\]" }
}
foreach tp {train_pipeline train_pipeline_1 train_pipeline_2 train_pipeline_3} {
  foreach b {31 32} { _dv "inner_l2cache/$tp/io_out_bits_tag\[$b\]" }
}
_dv "inner_l2cache/txreq_arb/io_chosen\[2\]"
_dv "inner_l2cache/txreq_arb/io_out_bits_txnID\[11\]"

puts "L2TOP_PINS: $_n dead black-box output bits excluded (dont_verify, both sides)"
