# =============================================================================
# fm_pins.tcl 的离线自测 —— ★证明那三层 fail-closed 判据不是空转★
#
# 为什么需要它：set_user_match 对不存在的名字**不报错**，所以 fm_pins.tcl 里
# "钉了 51 条" 这句话本身什么都不证明。本自测把 report_unmatched_points /
# set_user_match / exit 全打桩，喂真实的 51 条未读点（fixture），跑四个场景：
#   POSITIVE  正常输入            → 钉满 51、不 exit
#   NEG1      混进一个未知形状    → exit 3（形状闸）
#   NEG2      impl 侧少一个       → exit 3（双射/漏钉闸）
#   NEG3      推出的路径不在集合  → exit 3（防凭空造点）
# 三个负例都必须 exit 3；有一个不 exit，说明那层判据是摆设。
#
# 用法（不需要 Formality，纯 tclsh）：
#   cd verif/ut/RenameBuffer
#   tclsh diag/fm_pins_selftest.tcl fm_pins.tcl diag/unread_points_51.fixture.txt
#
# 实测（2026-09-17, commit 5c8643e 的 unread 集合）：
#   POSITIVE: pinned=51 exit=-1 rc=0
#   NEG1:     exit=3      NEG2: exit=3      NEG3: exit=3
#
# ★fixture 的定位★：diag/unread_points_51.fixture.txt 是 FM 那一跑导出的 51 条
# 未读点的**冻结副本**，只用于让负例可复跑。正例的权威判据**不是**它，而是真实
# FM 跑完之后 unmatched unread 是否归 0 —— fixture 会不会腐烂不影响那个判据。
# =============================================================================
set ::REF {}; set ::IMPL {}; set ::PINS {}; set ::EXITED -1
proc report_unmatched_points {args} {
    if {[lsearch -exact $args "-reference"] >= 0} { return $::REF }
    return $::IMPL
}
proc set_user_match {a b} { lappend ::PINS "$a|$b"; return 0 }
proc exit {code} { set ::EXITED $code; return -code error "EXIT$code" }
proc load_points {f} {
    set ::REF {}; set ::IMPL {}
    set fh [open $f r]
    while {[gets $fh line] >= 0} {
        set parts [split $line "\t"]
        if {[lindex $parts 0] eq "ref"} { lappend ::REF [lindex $parts 1] } else { lappend ::IMPL [lindex $parts 1] }
    }
    close $fh
}
proc run {pins label} {
    set ::PINS {}; set ::EXITED -1
    set rc [catch {uplevel #0 [list source $pins]} err]
    puts "$label: pinned=[llength $::PINS] exit=$::EXITED rc=$rc"
}
set pins [lindex $argv 0]; set pts [lindex $argv 1]
load_points $pts;                                   run $pins "POSITIVE(应 51 / exit=-1)"
load_points $pts; lappend ::REF "r:/WORK/RenameBuffer/someOtherDeadReg_reg\[3\]"
                                                    run $pins "NEG1 未知形状(应 exit=3)"
load_points $pts; set ::IMPL [lrange $::IMPL 0 end-1]
                                                    run $pins "NEG2 impl 少一个(应 exit=3)"
load_points $pts; set ::IMPL [lreplace $::IMPL 0 0 "i:/WORK/RenameBuffer/u_core/bogus_reg"]
                                                    run $pins "NEG3 推出路径不在集合(应 exit=3)"
