# MainPipe FM 钉点（FM 审计 2026-07）—— 匹配前(FM_PIN_PRE_TCL)版本。
# 实证: post-match 里 set_app_var(undriven/reg_init)与 set_user_match 常不生效
# (验证模型已按默认值构建/点已被签名错配), 必须在首次 match 前设置。
# 1) Arbiter4_MainPipeReq 两侧同定义，但 probe/refill 腿的 store_data/amo_* 输入脚
#    两侧都悬空。FM 默认 verification_set_undriven_signals=BINARY:X（ref 悬空=自由
#    割点、impl 悬空=X），凡比对点锥含悬空信号必失配。设 BINARY 让两侧悬空信号
#    按同名配对为同一自由变量，锥一致。
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} {
  puts "MAINPIPE_PINS: set_app_var failed: $msg"
}
# 2) Auto 模式下 FM 会用「寄存器初值推断」把一侧的部分寄存器约束成常量（两侧不对称
#    → 宽数据锥失配）。关掉初值假设，按纯次态函数比对。
if {[catch {set_app_var verification_assume_reg_init none} msg]} {
  puts "MAINPIPE_PINS: assume_reg_init failed: $msg"
}

set _n 0; set _f 0
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)"; incr ::_f } else { incr ::_n }
}

# 3) io_status_dup_0..23：golden 每份独立寄存器副本 ↔ 重写核 [24] 副本数组（1:1）。
for {set n 0} {$n < 24} {incr n} {
  for {set b 0} {$b < 8} {incr b} {
    _pin "r:/WORK/$top/io_status_dup_${n}_s1_bits_set_r_reg\[$b\]" \
         "i:/WORK/$top/u_core/status_s1_set_q_reg\[$n\]\[$b\]"
    _pin "r:/WORK/$top/io_status_dup_${n}_s2_bits_set_r_reg\[$b\]" \
         "i:/WORK/$top/u_core/status_s2_set_q_reg\[$n\]\[$b\]"
    _pin "r:/WORK/$top/io_status_dup_${n}_s3_bits_set_r_reg\[$b\]" \
         "i:/WORK/$top/u_core/status_s3_set_q_reg\[$n\]\[$b\]"
  }
  for {set b 0} {$b < 4} {incr b} {
    _pin "r:/WORK/$top/io_status_dup_${n}_s3_bits_way_en_r_reg\[$b\]" \
         "i:/WORK/$top/u_core/status_s3_way_q_reg\[$n\]\[$b\]"
  }
  # valid_r（replace 正相打拍）
  _pin "r:/WORK/$top/io_status_dup_${n}_s2_valid_r_reg" "i:/WORK/$top/u_core/status_s2_repl_q_reg\[$n\]"
  _pin "r:/WORK/$top/io_status_dup_${n}_s3_valid_r_reg" "i:/WORK/$top/u_core/status_s3_repl_q_reg\[$n\]"
}

# 4) RegNext(s0_fire) 四份副本 1:1（meta/encTag/repl-way 的选择寄存器 + replace_way_set_valid）
_pin "r:/WORK/$top/last_REG_reg"                          "i:/WORK/$top/u_core/s1_meta_sel_reg"
_pin "r:/WORK/$top/last_REG_1_reg"                        "i:/WORK/$top/u_core/s1_enctag_sel_reg"
_pin "r:/WORK/$top/s1_repl_way_en_last_REG_reg"           "i:/WORK/$top/u_core/s1_replway_sel_reg"
_pin "r:/WORK/$top/io_replace_way_set_valid_last_REG_reg" "i:/WORK/$top/u_core/replace_way_set_valid_q_reg"

puts "MAINPIPE_PRE_PINS: $_n pinned, $_f failed"
