# fm_conedce_partition_pinned.tcl (diag rev, codex 0107) — official-gate-shaped FM
# proof for a cone-DCE Rob partition. Both ref (reduced golden Rob) and impl
# (reduced impl Rob) expose ONLY the partition family's outputs; the off-cone
# logic has been PHYSICALLY removed from BOTH sides by the same locked
# cone-slicer (ref) / port-trim (impl). No dont_verify, no assumption, no
# constant-forcing, no added functional blackbox.
#
# Diag-rev changes vs /tmp/rob-soa-integ2-evidence/fm_conedce_partition_pinned.tcl:
#   (1) DPI sink stubs (FM_DPI_STUBS) read on BOTH sides -> DiffExtInstrCommit /
#       DiffExtTrapEvent resolve as empty all-input sink modules; FM sweeps the
#       difftest sink cones => 0 unknown-direction BBPin (FM-230), 0 missing
#       references (FM-064). Sink-only, no reverse influence.
#   (2) report_passing_points syntax fixed (V-2023.12 has no `-status pass`
#       option) + all reports wrapped in catch so post-verify reporting can
#       never abort the script (old rc=1 CMD-081 cause).
#   (3) failing points get report_failing_points + analyze_points -failing
#       evidence when present.
#   (4) explicit exit code: 0 iff verify returned success.

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

set dpi_stubs ""
if { [info exists env(FM_DPI_STUBS)] && [file exists $env(FM_DPI_STUBS)] } {
  set dpi_stubs $env(FM_DPI_STUBS)
}

read_sverilog -r -define {SYNTHESIS} [concat $ref_srcs $dpi_stubs]
set_top r:/WORK/$top

set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_ELAB-118
set_mismatch_message_filter -warn FMR_VLOG-091
set_mismatch_message_filter -warn FMR_VLOG-063

read_sverilog -i -define {SYNTHESIS} [concat $impl_srcs $dpi_stubs]
set_top i:/WORK/$top

# cone-DCE robEntries name-pins (pure set_user_match bijection; fail-closed)
if { [info exists env(FM_PINS)] && [file exists $env(FM_PINS)] } { source $env(FM_PINS) }

match

set vres 0
catch { set vres [verify] } _verify_msg
puts "FM_DIAG_VERIFY_RET=$vres"

catch { redirect unmatched.rpt  { report_unmatched_points } }
catch { redirect passing.rpt    { report_passing_points } }
catch { redirect failing.rpt    { report_failing_points } }
catch { redirect unverified.rpt { report_unverified_points } }
if { !$vres } {
  catch { redirect analyze_failing.rpt { analyze_points -failing } }
}

if { $vres } { exit 0 } else { exit 2 }
