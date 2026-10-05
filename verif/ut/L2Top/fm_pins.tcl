# L2Top FM「匹配后」钉点（动态）—— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）
# scripts/fm_eq.tcl 在首次 match、auto_match 之后 source 本文件，随后再 match。
# ---- nested-u_core prefix-aware matcher（codex 0215 Q2）----
# key：相对 top 的完整路径；impl 侧只删除**整段等于** u_core 的层次段；叶名数组展平
# （name_reg[i][j] -> name_i_j_reg；ref name_i_reg[j] -> name_i_j_reg）。只 DFF；两侧 key 必须唯一。
proc ucm_leaf {leaf} {
    if {[regexp {^(\w+)_reg((?:\[\d+\])*)$} $leaf -> nm bits]} {
        set idx ""
        foreach b [regexp -all -inline {\d+} $bits] { append idx "_$b" }
        return "${nm}${idx}_reg"
    }
    return $leaf
}
proc ucm_key {side path} {
    global top
    set pre "${side}:/WORK/${top}/"
    if {[string first $pre $path] != 0} { return "" }
    set segs [split [string range $path [string length $pre] end] /]
    set keep {}
    foreach s [lrange $segs 0 end-1] {
        if {$side eq "i" && $s eq "u_core"} continue
        lappend keep $s
    }
    lappend keep [ucm_leaf [lindex $segs end]]
    return [join $keep /]
}
proc ucm_collect {side} {
    set opt [expr {$side eq "r" ? "-reference" : "-implementation"}]
    set pts {}
    foreach st {{} unread} {
        if {$st eq ""} {
            set l [report_unmatched_points $opt -point_type dff -list]
        } else {
            set l [report_unmatched_points $opt -point_type dff -status unread -list]
        }
        foreach p $l { lappend pts $p }
    }
    return [lsort -unique $pts]
}
proc ucm_run {} {
    global top
    array set rk {}; array set ik {}
    set bad 0
    foreach side {r i} {
        foreach p [ucm_collect $side] {
            set k [ucm_key $side $p]
            if {$k eq ""} { puts "UCM_BADPATH: $side $p"; incr bad; continue }
            if {$side eq "r"} { lappend rk($k) $p } else { lappend ik($k) $p }
        }
    }
    set matched 0; set amb 0; set miss_r 0; set miss_i 0; set fail 0
    foreach side {r i} {
        upvar 0 [expr {$side eq "r" ? "rk" : "ik"}] m
        foreach k [lsort [array names m]] {
            if {[llength $m($k)] != 1} {
                incr amb
                if {$amb <= 20} { puts "UCM_AMBIGUOUS: side=$side key=$k pts=$m($k)" }
            }
        }
    }
    foreach k [lsort [array names rk]] {
        if {![info exists ik($k)]} { incr miss_r; continue }
        if {[llength $rk($k)] != 1 || [llength $ik($k)] != 1} continue
        set r [lindex $rk($k) 0]; set i [lindex $ik($k) 0]
        if {[set_user_match $r $i]} { incr matched } else {
            incr fail
            if {$fail <= 10} { puts "UCM_SET_FAIL: $r <-> $i" }
        }
    }
    foreach k [array names ik] { if {![info exists rk($k)]} { incr miss_i } }
    puts "UCM_SUMMARY $top matched=$matched ambiguous=$amb missing_ref=$miss_r missing_impl=$miss_i set_fail=$fail bad_path=$bad"
    if {$amb != 0 || $fail != 0 || $bad != 0} {
        error "UCM_FAIL ambiguous=$amb set_fail=$fail bad_path=$bad"
    }
}
ucm_run
