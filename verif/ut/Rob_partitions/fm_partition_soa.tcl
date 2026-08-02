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
# ★SoA-aware DFF auto-match (codex 0101)★ 正确机制: DFF-cell↔DFF-cell 配对(避 raw
#  net/cell FM-013 类型不匹配 + 避 packed 的 FM-036 unknown-name)。把 golden
#  robEntries_<N>_<field> DFF 映射到 impl SoA rob_<field>_reg[<N>](多位含 [b])DFF。
#  用 report_unmatched_points 拿两侧真实 DFF 对象(类型一致), 逐条 set_user_match。
proc soa_family_dff_match { top } {
    # golden_suffix -> impl SoA array leaf
    array set map {valid rob_valid_reg  stdWritebacked rob_std_wb_reg  uopNum rob_uop_num_reg}
    redirect -variable um {report_unmatched_points}
    array set impl_dff {}
    set ref_dffs {}
    foreach line [split $um "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rp]} {
            lappend ref_dffs $rp
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ip]} {
            # normalize impl leaf: rob_<field>_reg[N] or rob_uop_num_reg[N][b]
            set leaf [file tail $ip]
            set impl_dff($ip) 1
        }
    }
    set n 0
    foreach rp $ref_dffs {
        set leaf [file tail $rp]
        # golden leaf: robEntries_<N>_<field>  or  robEntries_<N>_<field>[b]
        if {![regexp {robEntries_(\d+)_([A-Za-z]+)(?:\[(\d+)\])?$} $leaf -> N fld b]} { continue }
        if {![info exists map($fld)]} { continue }
        set arr $map($fld)
        # build impl DFF path from ref path prefix (swap robEntries_N_field -> u_core/arr[N]([b]))
        set pre $rp
        regsub {robEntries_\d+_[A-Za-z]+(?:\[\d+\])?$} $pre "" pre
        regsub {^r:} $pre "i:" ipre
        if {$b eq ""} {
            set ip "${ipre}u_core/${arr}\[$N\]"
        } else {
            set ip "${ipre}u_core/${arr}\[$N\]\[$b\]"
        }
        if {![catch {set_user_match $rp $ip} msg]} {
            incr n
        } elseif {$n < 5} {
            puts "SOA_DFF_MATCH_FAIL: $rp <-> $ip : $msg"
        }
    }
    puts "SOA_FAMILY_DFF_MATCH: paired=$n"
}
if {[info exists env(FM_SOA_DFF_MATCH)] && $env(FM_SOA_DFF_MATCH) eq "1"} {
    # need a first match pass to populate unmatched DFF list
    match
    soa_family_dff_match $top
} elseif {[info exists env(FM_SOA_ENTRY_PINS)] && [file exists $env(FM_SOA_ENTRY_PINS)]} {
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
