# Rob SoA-canary partition FM driver (codex 0103 三修版).
# 与 fm_partition.tcl(packed 基线)语义一致, 唯一差异:
#   - impl 侧用 SoA 核(rob_pkg.sv/Rob.sv 已把 commit-state family 拆 SoA + nf packed
#     + Rob_packed_ref.sv 不进 impl srcs, 仅 co-sim 用);
#   - 家族匹配用 FM_SOA_ENTRY_PINS(1440 per-bit / reg set_user_match)配对 golden
#     robEntries_N_{valid,uopNum,stdWritebacked} ↔ impl rob_{valid,uop_num,std_wb}_reg[N];
#   - 其余 22 nf 字段留给 auto_match_flattened_arrays 的 name-match(rob_entries_nf_reg)。
# strict semantics 同基线: no dont_verify / no failing-point deletion / no assumption.
#
# ★codex 0103 修1★ 关键纪律: 全部 set_user_match 必须在【第一个 match 之前】完成。
#   旧版有 FM_SOA_DFF_MATCH=1 分支先跑一次全局 match 取 report_unmatched → SoA pin
#   来不及, 先撞 60k 墙。本版删除该前置-match 路径, 只走 pre-match name-driven pins,
#   并在首个 match 之前打印 "SOA_FAMILY_DFF_MATCH paired=<n> expected=<N>", 数量不符
#   立即 exit 7(证 pin 真生效, 非被 catch 吞掉的假 applied)。discovery 已证所有 pin
#   name(rob_valid_reg[N] / rob_uop_num_reg[N][b] / rob_std_wb_reg[N])pre-match 全解析
#   0 FM-036。
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

# ★修3★ 不再过滤 FMR_VLOG-091(可读核已把 14 个读 non-local 的 function 改为
#  always_comb 预算数组 → impl set_top 时 FMR_VLOG-091=0, 无需 filter 掩盖)。
#  仍保留 golden 侧 difftest 链的 FMR_ELAB-147(dt_160x1 越界)+ FMR_VLOG-063 过滤。
set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_VLOG-063
read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

set_mismatch_message_filter -warn FMR_ELAB-147
set_mismatch_message_filter -warn FMR_VLOG-063
read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

set t_read [clock seconds]
puts "SOA_PHASE read_done epoch=$t_read"

# ================== ALL set_user_match BEFORE first `match` ==================
# ---- SoA family reg/bit pins (name-driven, resolve pre-match, 0 FM-036) ----
if {[info exists env(FM_SOA_ENTRY_PINS)] && [file exists $env(FM_SOA_ENTRY_PINS)]} {
    source $env(FM_SOA_ENTRY_PINS)
    puts "SOA_ENTRY_PINS sourced: $env(FM_SOA_ENTRY_PINS)"
} else {
    puts "SOA_PIN_ASSERT_FAIL: FM_SOA_ENTRY_PINS not set/found — cannot pre-match family"
    exit 7
}
# ---- optional packed nf bit-pins (22 fields) if provided (also pre-match) ----
if {[info exists env(FM_NF_ENTRY_PINS)] && [file exists $env(FM_NF_ENTRY_PINS)]} {
    source $env(FM_NF_ENTRY_PINS)
    puts "NF_ENTRY_PINS sourced: $env(FM_NF_ENTRY_PINS)"
}

set t_pin [clock seconds]
puts "SOA_PHASE pins_done epoch=$t_pin dt=[expr {$t_pin-$t_read}]"
# ★修1 assert★ the pins file prints "SOA_FAMILY_DFF_MATCH paired=<n> expected=<N>"
#  and exits 7 on mismatch — reaching here means the family is fully pre-matched.
puts "SOA_PREMATCH_COMPLETE: all family set_user_match applied BEFORE first match"

# ============================ first `match` ============================
match
set t_match [clock seconds]
puts "SOA_PHASE match_done epoch=$t_match dt=[expr {$t_match-$t_pin}]"

# same flattened-array auto-match as baseline (covers nf name-match + residual).
# NOTE: this is a POST-match refinement for the non-family (nf) 22 fields only;
# the family (valid/uopNum/stdWritebacked) is already pinned pre-match above.
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
