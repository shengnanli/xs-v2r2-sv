# ============================================================================
# DIAGNOSTIC ONLY - not part of any signoff flow.
# Reproduces scripts/fm_eq.tcl's appvar setup verbatim, then dumps the two
# reports Formality itself points at when it prints
#   "Constant registers have been identified that were initialized by some
#    objects that were assumed to toggle."
# namely report_potentially_constant_registers / report_init_toggle_objects,
# for BOTH sides, so ref-vs-impl asymmetry can be read off directly.
#
# env: DIAG_TOP DIAG_REF_SRCS DIAG_IMPL_SRCS DIAG_MERGE_DUP DIAG_TAG
# ============================================================================
set top   $env(DIAG_TOP)
set ref_srcs  $env(DIAG_REF_SRCS)
set impl_srcs $env(DIAG_IMPL_SRCS)
set mergedup  $env(DIAG_MERGE_DUP)
set tag       $env(DIAG_TAG)

# --- identical appvar block to scripts/fm_eq.tcl (signoff-strict) -----------
set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers $mergedup

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

match

proc dump {label cmd} {
    global tag
    puts "@@@@ BEGIN $label ($tag)"
    if {[catch {uplevel 1 [list redirect -variable _t $cmd]} msg]} {
        puts "@@@@ CMDERR $label : $msg"
    } else {
        upvar 1 _t t
        puts $t
    }
    puts "@@@@ END $label ($tag)"
}

# NOTE: these two commands have no -reference/-implementation switch (man cat2);
# one report covers both sides, objects are prefixed r:/ and i:/.
dump PCR       {report_potentially_constant_registers}
dump PCR_INFO  {report_potentially_constant_registers -info}
dump PCR_NOTOG {report_potentially_constant_registers -assumed_no_toggle}
dump ITO       {report_init_toggle_objects}
dump UNMATCHED {report_unmatched_points}

# how many r_<N>_reg objects survive on each side inside the shared golden array
foreach side {r i} {
    if {$side eq "r"} { set hp "r:/WORK/$top/mulDataModule" } \
                 else { set hp "i:/WORK/$top/u_core/mulDataModule" }
    puts "@@@@ BEGIN CELLS_$side ($tag) path=$hp"
    if {[catch {puts "all_cells=[sizeof_collection [get_cells -quiet $hp/*]]"} m2]} { puts "err $m2" }
    if {[catch {
        set rr [get_cells -quiet $hp/r_*_reg]
        puts "r_N_reg_cells=[sizeof_collection $rr]"
    } m3]} { puts "err $m3" }
    # the 31 sticky "r_N <= io_regEnables_0 | r_N" registers, by name
    set sticky {1285 1348 1409 1468 1525 1580 1633 1684 1733 1780 1825 1868 1909
                1948 1985 2020 2053 2084 2113 2140 2165 2188 2209 2228 2245 2260
                2273 2284 2293 2300 2305}
    set present {}
    set absent {}
    foreach n $sticky {
        set c [get_cells -quiet $hp/r_${n}_reg]
        if {[sizeof_collection $c] > 0} { lappend present $n } else { lappend absent $n }
    }
    puts "sticky_present([llength $present])=$present"
    puts "sticky_absent([llength $absent])=$absent"
    puts "@@@@ END CELLS_$side ($tag)"
}

# matched partners of the sticky r_<N>_reg family
dump MATCHED_STICKY {report_matched_points -point_type DFF -status unread}

if {[verify]} { puts "DIAG_RESULT($tag): SUCCEEDED" } else { puts "DIAG_RESULT($tag): FAILED_OR_INCONCLUSIVE" }
exit
