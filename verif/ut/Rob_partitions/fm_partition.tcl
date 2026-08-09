# Rob Route B partition FM driver (self-contained, signoff-strict semantics).
# Compares golden Rob (ref) vs impl Rob_wrapper (impl) THROUGH a partition
# harness module Rob_p<Fam> that exposes ONLY that family's outputs.
#   FM_TOP        = Rob_p<Fam>  (partition module; identical text both sides)
#   FM_REF_SRCS   = partition_part.sv + golden Rob.sv + golden deps
#   FM_IMPL_SRCS  = partition_part.sv + impl Rob_wrapper.sv + Rob.sv(core) + deps
# strict: no dont_verify, no failing-point deletion, no extra assumption,
# no matched-unread strengthening. Only symmetric black boxes = difftest DPI
# sinks (DiffExtInstrCommit*/DiffExtTrapEvent) via hdlin_unresolved_modules.
set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# unread six-tuple: frozen 305 execution semantics (verbatim from scripts/fm_eq.tcl)
set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers true

# benign index/select filters (identical to full-Rob evidence tcl, both sides):
#   FMR_ELAB-147 golden dt_160x1 difftest mem out-of-bound index (difftest chain, no top-output)
#   FMR_ELAB-118 struct-return init ; FMR_VLOG-091/063 residual warnings
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

# Pre-match rob_entries[i] array pins (FM_ENTRY_PINS, optional): name-driven match
# for the 160-entry packed-struct array, so `match` is not signature-bound (the
# compute wall). Pure set_user_match, no dont_verify / no ref constraint.
if {[info exists env(FM_ENTRY_PINS)] && [file exists $env(FM_ENTRY_PINS)]} {
    source $env(FM_ENTRY_PINS)
    puts "ENTRY_PINS sourced: $env(FM_ENTRY_PINS)"
}

match

# auto-pair firtool-flattened (ref) vs SV-array (impl) register names — same proc
# as scripts/fm_eq.tcl auto_match_flattened_arrays, restricted to u_core hierarchy.
proc auto_match_flattened_arrays { top } {
    redirect -variable um_txt {report_unmatched_points}
    array set impl_lut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rpath]} {
            lappend refs $rpath
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ipath]} {
            set rel $ipath
            regsub "^i:/WORK/${top}/u_rob/" $rel "" rel
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
        regexp {^(.*?)((?:\[\d+\])*)$} $leaf -> base bit
        set bitidx ""
        foreach b [regexp -all -inline {\d+} $bit] { set bitidx "_$b" }
        set cand ""
        if {[regexp {^(.*)_reg$} $base -> nm]} { set cand "${nm}${bitidx}_reg" }
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
    if {$n > 0} { match; puts "AUTO_MATCH: $n flattened-array pairs" }
}
auto_match_flattened_arrays $top

report_unmatched_points > unmatched.rpt
report_matched_points    > matched.rpt

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
exit
