# ============================================================================
# CtrlBlock PARTITION CANARY — "glue" partition (Worker H, agent/ctrlblock-w)
# ----------------------------------------------------------------------------
# See verif/ut/CtrlBlock/PARTITION_PLAN.md for the full diagnosis + plan.
#
# The monolithic FM run reads ALL 22 golden submodules (Rob=220K lines,
# NewDispatch=20K, ...) on BOTH ref and impl, so Formality flattens a ~320K+
# line design and STALLS in "Elaborating design Rob" (ref-side model
# construction) before any matching.
#
# Partition strategy (SOUND, not a waiver):
#   The impl readable core xs_CtrlBlock_core instantiates the *byte-identical*
#   golden submodules by the *same instance names* as golden CtrlBlock. So the
#   ONLY logic that differs between ref and impl is the CtrlBlock GLUE.
#   => Black-box the 22 submodules SYMMETRICALLY (do NOT feed their bodies to
#      read_sverilog; hdlin_unresolved_modules black_box catches them on both
#      sides). FM then builds a verification model for the glue only, and the
#      submodule black boxes become boundary compare points.
#
# Composition obligation (must be discharged SEPARATELY; documented in the plan):
#   Each black-boxed submodule S must be proven ref(S) == impl(S). Here that is
#   trivial (impl instantiates the same golden .sv). In the full REPLACEMENT
#   program each S is its own signoff target.
#
# This canary is a partitioned DIAGNOSTIC, NOT a signoff-strict pass. It uses NO
# dont_verify, NO hidden point deletion, NO wildcard, NO timeout extension.
# Invoke: FM_TOP=CtrlBlock FM_REF_SRCS=<golden/CtrlBlock.sv>
#         FM_IMPL_SRCS="<pkg> <core> <wrapper>" FM_PIN_TCL=<fm_pins.tcl>
#         fm_shell -64 -work_path fm_work/CtrlBlock -file fm_canary_glue.tcl
# ============================================================================

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# --- appvars mirror signoff fm_eq.tcl (strict semantics; no relaxation) ------
set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true

# Unresolved (un-fed) submodules become black boxes on BOTH sides.
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers true

# Reference: ONLY the golden CtrlBlock top (glue). Submodules unresolved.
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

# Implementation: readable core + wrapper (glue). Submodules unresolved.
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# auto_match_flattened_arrays: copied verbatim from scripts/fm_eq.tcl so the
# canary uses identical matching machinery (Chisel flattened names <-> SV arrays).
proc auto_match_flattened_arrays { top } {
    redirect -variable um_txt {report_unmatched_points}
    array set impl_lut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rpath]} {
            lappend refs $rpath
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ipath]} {
            set rel $ipath
            regsub "^i:/WORK/${top}/" $rel "" rel
            regsub "^u_core/" $rel "" rel
            set key $rel
            regexp {^(.*?)((?:\[\d+\])*)$} $rel -> stem bits
            set idxs ""
            set blist [regexp -all -inline {\d+} $bits]
            if {[regexp {^(.*)_reg$} $stem -> nm]} {
                foreach b $blist { append idxs "_$b" }
                set key "${nm}${idxs}_reg"
            }
            set impl_lut($key) $ipath
        }
    }
    set n 0
    foreach rpath $refs {
        set leaf [file tail $rpath]
        set dir  [file dirname $rpath]
        regsub "^r:/WORK/${top}" $dir "" relhier
        regsub {^/} $relhier "" relhier
        regexp {^(.*?)((?:\[\d+\])*)$} $leaf -> base bit
        set bitidx ""
        foreach b [regexp -all -inline {\d+} $bit] { set bitidx "_$b" }
        set cand ""
        if {[regexp {^(.*)_reg$} $base -> nm]} {
            set cand "${nm}${bitidx}_reg"
        }
        set hit ""
        foreach key [list $cand $base] {
            if {$key ne "" && [info exists impl_lut($key)]} { set hit $key; break }
        }
        if {$hit eq ""} { continue }
        set ipath $impl_lut($hit)
        if {![catch {set_user_match $rpath $ipath} msg]} {
            unset impl_lut($hit); incr n
        }
    }
    if {$n > 0} { match }
    puts "AUTO_MATCH_FLATTENED: $n pinned"
}

# Initial match (same ordering as signoff fm_eq.tcl) populates the unmatched
# list that the pin proc consumes.
match
auto_match_flattened_arrays $top

# Reuse the committed CtrlBlock glue pin map (flattened golden payload names <->
# struct/array impl regs). Runs AFTER the first match, then re-match.
if {[info exists env(FM_PIN_TCL)] && [file exists $env(FM_PIN_TCL)]} {
    source $env(FM_PIN_TCL)
    match
}

report_unmatched_points > unmatched.rpt
report_matched_points   > matched.rpt

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top (glue partition)"
} else {
    report_failing_points > failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top (glue partition)"
}
exit
