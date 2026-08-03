# Fast impl-only FMR check: read_sverilog -i the SoA core; assert FMR_VLOG-091 &
# FMR_ELAB-118 = 0 (the two FMR classes the canary drove to 0 and must stay 0).
# No golden, no match, no verify — just elaborate the impl core.
set impl_srcs [split $env(FMR_IMPL_SRCS)]
set top $env(FMR_TOP)
set_app_var hdlin_unresolved_modules black_box
# keep pre-existing benign filters (same as fm_partition_soa.tcl) so we only
# surface the two classes we care about.
set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_VLOG-063
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top
puts "FMR_CHECK_ELABORATE_DONE top=$top"
exit 0
