# VARIANTS: TlbStorageWrapper TlbStorageWrapper_1 TlbStorageWrapper_2 TlbStorageWrapper_3
# ---------------------------------------------------------------------------
# TlbStorageWrapper 家族钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# ★这一族的形状必须从 evidence 现取，推不出来★：钉点打在**内层阵列实例**上
# （scope 是 /WORK/<top>/<内层实例>，两层），而哪个变体有未读点、内层实例叫什么，
# 都不是数 golden 声明能得到的。取已提交 evidence（evidence/c62139c3f07b/TlbStorageWrapper*）：
#   TlbStorageWrapper    -> 没有未匹配的未读点（0 次调用）
#   TlbStorageWrapper_1  -> 同上（0 次调用）
#   TlbStorageWrapper_2  -> page_sttlb_storage_fa，端口 0/1，11 位 x 2 = 22
#   TlbStorageWrapper_3  -> page_pftlb_storage_fa，端口 0/1，11 位 x 2 = 22
# 复算：evidence 里逐条 grep `r:/WORK/TlbStorageWrapper*/…/reqVpn*_reg[…]`。
#
# ★注意★：前两个变体在本钉点文件里走的是"没有未读点就啥也不做"那条支路。
# 那条支路在 TLBFA/TLBNonBlock/RenameBuffer 上已经被删掉（期望值是正数时，
# 观测到零必须是红），本文件还留着 —— 它不在本轮那 14 个之列，属于存量。
# 夹具如实反映现状，不替它做主。
# ---------------------------------------------------------------------------
proc _fx_tlbsw {} {
    global top
    switch -exact -- $top {
        TlbStorageWrapper   { return {} }
        TlbStorageWrapper_1 { return {} }
        TlbStorageWrapper_2 { return {page_sttlb_storage_fa 2} }
        TlbStorageWrapper_3 { return {page_pftlb_storage_fa 2} }
    }
    error "TlbStorageWrapper fixture: unknown variant $top"
}
proc report_unmatched_points {args} {
    global top
    set shape [_fx_tlbsw]
    if {[llength $shape] == 0} { return {} }
    lassign $shape inner ports
    set ref {} ; set impl {}
    for {set p 0} {$p < $ports} {incr p} {
        set sfx [expr {$p == 0 ? "" : "_$p"}]
        for {set b 27} {$b <= 37} {incr b} {
            lappend ref  "r:/WORK/$top/$inner/reqVpn${sfx}_reg\[$b\]"
            lappend impl "i:/WORK/$top/$inner/u_core/g_port\[$p\].req_vpn_q_reg\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
