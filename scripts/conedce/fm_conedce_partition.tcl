# fm_conedce_partition.tcl — official-gate-shaped FM proof for a cone-DCE Rob
# partition. Both ref (reduced golden Rob) and impl (reduced impl Rob) expose
# ONLY the partition family's outputs; the off-cone logic has been PHYSICALLY
# removed from BOTH sides by the same locked cone-slicer (ref) / port-trim (impl).
# No dont_verify, no assumption, no constant-forcing, no added blackbox. The only
# symmetric black boxes are the difftest DPI-C sinks (same 9 as allow/Rob.json),
# present only when the family's cone reaches them.
#
# Semantics copied verbatim from scripts/fm_eq.tcl / routeB fm_partition.tcl.

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set hdlin_unresolved_modules black_box

set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_ELAB-118
set_mismatch_message_filter -warn FMR_VLOG-091
set_mismatch_message_filter -warn FMR_VLOG-063

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_ELAB-118
set_mismatch_message_filter -warn FMR_VLOG-091
set_mismatch_message_filter -warn FMR_VLOG-063

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

match
verify

redirect unmatched.rpt { report_unmatched_points }
redirect passing.rpt   { report_passing_points -status pass }
redirect failing.rpt   { report_failing_points }
exit
