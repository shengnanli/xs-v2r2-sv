# Rob SoA-canary partition FM driver (codex 0101 阶段1).
# 与 fm_partition.tcl(packed 基线)语义一致, 唯一差异:
#   - impl 侧用 SoA 核(rob_pkg.sv/Rob.sv 已把 commit-state family 拆 SoA + nf packed
#     + Rob_packed_ref.sv 不进 impl srcs, 仅 co-sim 用);
#   - 家族匹配用 FM_SOA_ENTRY_PINS(480 reg-level set_user_match)替 9440 bit-pins;
#   - 其余 22 nf 字段留给 auto_match_flattened_arrays 的 name-match(rob_entries_nf_reg)
#     或(FM_ENTRY_PINS 若给)packed nf bit-pins。
# strict semantics 同基线: no dont_verify / no failing-point deletion / no assumption.
set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

set_app_var verification_verify_unread_compare_points false
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set_app_var hdlin_unresolved_modules black_box
set_app_var verification_merge_duplicated_registers true

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

set t_read [clock seconds]
puts "SOA_PHASE read_done epoch=$t_read"

# ---- SoA family reg-level pins (480, name-driven whole-reg match) ----
if {[info exists env(FM_SOA_ENTRY_PINS)] && [file exists $env(FM_SOA_ENTRY_PINS)]} {
    source $env(FM_SOA_ENTRY_PINS)
    puts "SOA_ENTRY_PINS sourced: $env(FM_SOA_ENTRY_PINS)"
}
# ---- optional packed nf bit-pins (22 fields) if provided ----
if {[info exists env(FM_NF_ENTRY_PINS)] && [file exists $env(FM_NF_ENTRY_PINS)]} {
    source $env(FM_NF_ENTRY_PINS)
    puts "NF_ENTRY_PINS sourced: $env(FM_NF_ENTRY_PINS)"
}

set t_pin [clock seconds]
puts "SOA_PHASE pins_done epoch=$t_pin dt=[expr {$t_pin-$t_read}]"

match
set t_match [clock seconds]
puts "SOA_PHASE match_done epoch=$t_match dt=[expr {$t_match-$t_pin}]"

# same flattened-array auto-match as baseline (covers nf name-match + residual)
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
set t_am [clock seconds]
puts "SOA_PHASE automatch_done epoch=$t_am dt=[expr {$t_am-$t_match}]"

report_unmatched_points > unmatched.rpt
report_matched_points    > matched.rpt

if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    report_failing_points > failing.rpt
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
set t_end [clock seconds]
puts "SOA_PHASE verify_done epoch=$t_end dt=[expr {$t_end-$t_am}]"
exit
