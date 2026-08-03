# 一次性诊断: 复刻 fm_eq_full 流程 + verify 后 analyze_points (排障用, 不入常规流程)
set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)
set_app_var verification_verify_unread_compare_points false
set_app_var hdlin_unresolved_modules black_box
if {[info exists env(FM_INTERFACE_ONLY)]} { set_app_var hdlin_interface_only $env(FM_INTERFACE_ONLY) }
set_app_var verification_merge_duplicated_registers false
set_app_var verification_failing_point_limit 5000
set_mismatch_message_filter -warn FMR_ELAB-147
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top
if {[info exists env(FM_PIN_PRE_TCL)] && [file exists $env(FM_PIN_PRE_TCL)]} {
    source $env(FM_PIN_PRE_TCL)
}
match
if {[verify]} { puts "FM_RESULT: SUCCEEDED" } else { puts "FM_RESULT: FAILED" }
analyze_points -all > fm_work/NewIFU/analyze.rpt
report_failing_points -inputs unmatched -inputs undriven > fm_work/NewIFU/failing_undriven.rpt
exit
