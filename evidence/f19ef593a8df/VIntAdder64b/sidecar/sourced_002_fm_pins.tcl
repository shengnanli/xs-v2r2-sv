# ArithVecLeaves5 FM pin script -- only DivUnit has work here; the other 4
# variants of this UT return immediately (this file is sourced per-target,
# $top is the current FM_TOP).
#
# What is pinned and why (DivUnit only):
#   6 dead register bits inside the golden child SRT16DividerDataModule that
#   BOTH sides read from the same golden file (same sha256 in both closures):
#     aLZCReg_reg[6] dLZCReg_reg[6]        -- bit6 constantly 0, readers use [5:0]
#     udNegReg_{0,1,3,4}_reg[67]           -- readers use [65:0] / [66] / [66:57]
#   They are unread (no fanout) so signature analysis cannot pair them, and
#   plain name matching fails because the child instance path differs
#   (ref divDataModule vs impl u_core/u_div). Result: 6 ref + 6 impl
#   unmatched unread points. Pin them pairwise (bijection, fail-closed),
#   then vmucp (whitelist verif/fm_target_config/DivUnit.tcl) VERIFIES each
#   pair -- this is strengthening, not a waiver.
#
# Expected counts are mechanically derived: exactly the 6 leaf names below,
# 1 bit each. Runs in sidecar's safe child interp (no file/redirect/exit);
# every self-check failure raises `error`. All puts output is ASCII.
#
# NOTE: the expected set is the FM_MERGE_DUP=false register inventory (the
# canonical config for DivUnit, see Makefile). Under merge=on several of
# these bits are merged away and the counts below fail loudly by design.

if {$top eq "DivUnit"} {

proc _divunit_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

set _expected [list \
    "aLZCReg_reg\[6\]" \
    "dLZCReg_reg\[6\]" \
    "udNegReg_0_reg\[67\]" \
    "udNegReg_1_reg\[67\]" \
    "udNegReg_3_reg\[67\]" \
    "udNegReg_4_reg\[67\]"]

set refs  [report_unmatched_points -reference      -status unread -list]
set impls [report_unmatched_points -implementation -status unread -list]

puts "DIVUNIT_PIN_BEGIN expect=6 ref_unread=[llength $refs] impl_unread=[llength $impls]"

# fail-closed: the unread sets must be exactly the 6 known dead bits.
if {[llength $refs] != 6} {
    puts "DIVUNIT_PIN_ERROR: ref unread count [llength $refs] != 6"
    error "DIVUNIT_PIN_REF_COUNT=[llength $refs]"
}
if {[llength $impls] != 6} {
    puts "DIVUNIT_PIN_ERROR: impl unread count [llength $impls] != 6"
    error "DIVUNIT_PIN_IMPL_COUNT=[llength $impls]"
}

array set impl_lut {}
foreach ip $impls {
    set leaf [_divunit_leaf $ip]
    if {[lsearch -exact $_expected $leaf] < 0} {
        puts "DIVUNIT_PIN_ERROR: unexpected impl unread leaf $leaf"
        error "DIVUNIT_PIN_IMPL_LEAF=$leaf"
    }
    if {[info exists impl_lut($leaf)]} {
        puts "DIVUNIT_PIN_ERROR: duplicate impl unread leaf $leaf"
        error "DIVUNIT_PIN_IMPL_DUP=$leaf"
    }
    set impl_lut($leaf) $ip
}

set n 0
foreach rpath $refs {
    set leaf [_divunit_leaf $rpath]
    if {[lsearch -exact $_expected $leaf] < 0} {
        puts "DIVUNIT_PIN_ERROR: unexpected ref unread leaf $leaf"
        error "DIVUNIT_PIN_REF_LEAF=$leaf"
    }
    if {![info exists impl_lut($leaf)]} {
        puts "DIVUNIT_PIN_ERROR: no impl partner for $rpath"
        error "DIVUNIT_PIN_NO_PARTNER=$leaf"
    }
    if {![set_user_match $rpath $impl_lut($leaf)]} {
        puts "DIVUNIT_PIN_ERROR: set_user_match returned 0 for $rpath"
        error "DIVUNIT_PIN_SET_FAILED=$rpath"
    }
    unset impl_lut($leaf)
    incr n
}

if {[array size impl_lut] != 0} {
    puts "DIVUNIT_PIN_ERROR: [array size impl_lut] impl unread points left unpaired"
    error "DIVUNIT_PIN_LEFTOVER=[array size impl_lut]"
}
if {$n != 6} {
    puts "DIVUNIT_PIN_ERROR: pinned $n but expected 6"
    error "DIVUNIT_PIN_COUNT=$n"
}
puts "DIVUNIT_PIN_END pinned=$n"

}
