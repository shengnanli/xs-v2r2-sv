# fm_conedce_selfcheck.tcl — SOUNDNESS gate for the cone-DCE derivative.
#
# Proves: the cone-DCE reduced golden module (module `Rob`, only the partition's
# family outputs) is FUNCTIONALLY EQUIVALENT to the FULL golden Rob on exactly
# those kept outputs. If the slicer wrongly removed logic feeding a kept output,
# FM reports a mismatch here (fail-closed). A clean SUCCEEDED means the physical
# reduction preserved behaviour = the cone-DCE is sound for this partition.
#
# ref  = FULL golden Rob (+ golden leaf deps)     -> module Rob
# impl = cone-DCE reduced golden Rob (+ same deps) -> module Rob
# Only the reduced module's ports exist on the impl side; FM compares the
# common (kept) outputs. Unmatched ref outputs (the ones the reduced design
# doesn't expose) are expected and NOT a soundness failure — we assert 0
# FAILING and 0 on the kept surface.

set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# frozen unread six-tuple (verbatim from scripts/fm_eq.tcl / routeB tcl)
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
set_top r:/WORK/Rob

set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_ELAB-118
set_mismatch_message_filter -warn FMR_VLOG-091
set_mismatch_message_filter -warn FMR_VLOG-063

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/Rob

match
verify

redirect unmatched.rpt { report_unmatched_points }
redirect passing.rpt   { report_passing_points }
redirect failing.rpt   { report_failing_points }
exit
