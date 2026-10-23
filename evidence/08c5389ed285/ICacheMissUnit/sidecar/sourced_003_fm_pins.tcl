# ICacheMissUnit FM 钉点（agent/err3, 2026-09-14）
# ---------------------------------------------------------------------------
# 对称内部死位：TileLink Grant 的 beats1 倒计数器，两侧各 1 位，名字不同。
#   golden : r:/WORK/ICacheMissUnit/refill_done_r_counter_reg
#   可读核 : i:/WORK/ICacheMissUnit/u_core/grant_beat_left_q_reg
#
# 为什么是死的（两侧同因）：这个 1 位计数器唯一的读出点是 Scala 的
#   assert(!(refill_done ^ last_fire), "refill not done!")（ICacheMissUnit.scala:348）。
#   golden 把它放在 `ifndef SYNTHESIS 的 always 块里（ICacheMissUnit.sv:410-417），
#   可读核放在同样的 `ifndef SYNTHESIS 块里（rtl/frontend/ICacheMissUnit.sv:455-469）。
#   FM 两侧都带 -define SYNTHESIS 读入，断言整块被编译掉 ⇒ 计数器写了从不被读。
#   （它自己的次态用到自己，但自反馈不构成"被读"。）
#
# 为什么两侧本该配上却没配：叶名词干完全不同（refill_done_r_counter vs
#   grant_beat_left_q），层次也差一层 u_core，名字过滤匹配不上；又因为它是 unread、
#   不进比对，签名分析也不会去救它 ⇒ 1 (ref) + 1 (impl) unmatched-unread。
#   二者是严格 1↔1 双射：同为 io_mem_grant_valid 使能、同一个 beats1 次态函数
#     golden: if (valid) counter <= counter ? counter-1 : beats1   （1 位 ⇒ counter-1 即 0）
#     impl  : if (valid) q       <= q       ? 1'b0     : multi_beat
#   钉上之后配合 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true（加强，非放宽），
#   FM 会真的把这一对当比对点去证 —— 见 UT Makefile 里的验收记录。
#
# 只 set_user_match 消名差：不约束 ref、不 dont_verify、不扩黑盒。
# ---------------------------------------------------------------------------
if {[catch {set_user_match "r:/WORK/$top/refill_done_r_counter_reg" \
                           "i:/WORK/$top/u_core/grant_beat_left_q_reg"} _e]} {
  puts "ICACHEMISSUNIT_PINS: beats1 counter 钉点失败: $_e"
} else {
  puts "ICACHEMISSUNIT_PINS: beats1 counter 1 point pinned"
}
