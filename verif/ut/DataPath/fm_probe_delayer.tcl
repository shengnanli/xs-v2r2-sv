# DataPath difftest-delayer 失配单点探针(FM 审计 2026-07, 模块本地脚本)
# 复现 run1 条件(默认 merge, 无全量 verify),对单个失配点做 verify + analyze_points,
# 拿工具自己的失配解释(支持锥不齐/反例赋值),定性 DFF vs DFF0X 根因。
set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)
set_app_var verification_verify_unread_compare_points false
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers true
set_mismatch_message_filter -warn FMR_ELAB-147
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top
match
# 单点验证:Int 状态 delayer 第 0 拍第 0 位
set rp "r:/WORK/$top/difftestArchIntRegState_delayer/REG_value_0_reg\[0\]"
set ip "i:/WORK/$top/u_core/difftestArchIntRegState_delayer/REG_value_0_reg\[0\]"
verify $rp $ip
report_failing_points > fm_work/$top/probe_failing.rpt
analyze_points -failing > fm_work/$top/probe_analyze.rpt
# 支持锥对比
redirect fm_work/$top/probe_support.rpt {
  puts "==== REF support ===="
  report_support -point $rp
  puts "==== IMPL support ===="
  report_support -point $ip
}
puts "PROBE_DONE"
exit
