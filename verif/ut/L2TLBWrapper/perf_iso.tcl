set_app_var verification_verify_unread_compare_points false
read_sverilog -r $env(FM_REF_SRCS)
set_top r:/WORK/perf_iso
read_sverilog -i $env(FM_IMPL_SRCS)
set_top i:/WORK/perf_iso
match
if {[verify]} { puts "ISO_RESULT: SUCCEEDED" } else { puts "ISO_RESULT: FAILED" }
exit
