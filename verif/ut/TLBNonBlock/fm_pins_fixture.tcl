# VARIANTS: TLBNonBlock TLBNonBlock_1 TLBNonBlock_2
# ---------------------------------------------------------------------------
# TLBNonBlock 家族钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 两族数量的**出处不同**，别混：
#   A 族（first_issue 的匿名 RegNext）= golden `reg r[_N];` 条数 8 / 4 / 2（机械现数）
#   B 族（result_ok_last_REG 无后缀那个）= 0 / 0 / 1 —— 数声明看不出来
#       （三个变体 golden 里都有它，是不是"未匹配未读点"取决于该变体里有没有读者），
#       取已提交 evidence 的实测值：evidence/{88d4f00d0fe1,522c3fe3d5dd}/TLBNonBlock*/fm.log
# ---------------------------------------------------------------------------
proc _fx_shape {} {
    global top
    switch -exact -- $top {
        TLBNonBlock   { return {8 0} }
        TLBNonBlock_1 { return {4 0} }
        TLBNonBlock_2 { return {2 1} }
    }
    error "TLBNonBlock fixture: unknown variant $top"
}
proc report_unmatched_points {args} {
    global top
    lassign [_fx_shape] na nb
    set ref {} ; set impl {}
    for {set n 0} {$n < $na} {incr n} {
        if {$n == 0} { lappend ref "r:/WORK/$top/r_reg" } \
                else { lappend ref "r:/WORK/$top/r_${n}_reg" }
        set lane [expr {$n / 2}]
        if {$n % 2 == 0} {
            lappend impl "i:/WORK/$top/u_core/first_issue_r_reg\[$lane\]"
        } else {
            lappend impl "i:/WORK/$top/u_core/first_issue_r2_reg\[$lane\]"
        }
    }
    if {$nb > 0} {
        lappend ref  "r:/WORK/$top/result_ok_last_REG_reg"
        lappend impl "i:/WORK/$top/u_core/result_ok_last_reg\[0\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
