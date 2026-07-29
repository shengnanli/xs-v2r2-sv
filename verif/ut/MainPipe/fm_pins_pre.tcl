# MainPipe FM 钉点（FM 审计 2026-07）—— 匹配前(FM_PIN_PRE_TCL)版本。
# 实证: post-match 里 set_app_var(undriven/reg_init)与 set_user_match 常不生效
# (验证模型已按默认值构建/点已被签名错配), 必须在首次 match 前设置。
# NOTE(deadref-contract-B, codex_0089): the two relaxing appvars formerly set here
#   set_app_var verification_set_undriven_signals BINARY   (FM default BINARY:X)
#   set_app_var verification_assume_reg_init      none      (FM default auto)
# were REMOVED. Empirically they masked NO impl defect: with the FM defaults the
# MainPipe native proof is still SUCCEEDED with failing=0, unmatched=0,
# unread_impl=0 and the SAME 77 golden-only cone-dead unread_ref residual (removing
# them only shifts passing 8932->8930). Critically, both registered spurious
# relaxed_appvars qualifications that forced PARTIAL. There is no impl over-wide
# register / multi-driver / undriven-signal asymmetry to fix (impl side is 100%
# clean). The residual 77 points are declared golden-only cone-dead in
# verif/signoff/dead_ref/MainPipe.json (debug SC-conflict regs, assertion regs,
# dangling _GEN wires, never-read byte-offset/reserved bits). Removing the relaxes
# makes the proof a clean strict PASS_DEAD_REF with zero qualifications.

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

# 4) RegNext(s0_fire) 三份副本 1:1（meta/encTag/repl-way 的选择寄存器）
#    注：golden 的 io_replace_way_set_valid_last_REG 是冗余死寄存器（其唯一去向 _GEN_2
#        在本 firtool 配置下无扇出），impl 已正确省略——它在 golden 侧成 cone-dead
#        (PASS_DEAD_REF)，无需/无法钉点。
_pin "r:/WORK/$top/last_REG_reg"                          "i:/WORK/$top/u_core/s1_meta_sel_reg"
_pin "r:/WORK/$top/last_REG_1_reg"                        "i:/WORK/$top/u_core/s1_enctag_sel_reg"
_pin "r:/WORK/$top/s1_repl_way_en_last_REG_reg"           "i:/WORK/$top/u_core/s1_replway_sel_reg"

puts "MAINPIPE_PRE_PINS: $_n pinned, $_f failed"
