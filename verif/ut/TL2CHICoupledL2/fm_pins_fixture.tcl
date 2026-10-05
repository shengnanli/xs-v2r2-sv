# VARIANTS: TL2CHICoupledL2
# fm_pins.tcl 的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）—— 自动生成：scripts/gen_tl2chi_pins.py
# 造 2 个 slice × 2 个 MSHR 槽的展平寄存器：ref <pfx>slices_<k>/mshrCtl/q_<j>_reg[<b>]，
# impl <pfx>slices_<k>/u_core/mshrCtl/u_core/q_reg[<j>][<b>]；匹配器应恰好配上 8 对、按 key 排序发射。
proc report_unmatched_points {args} {
    global top
    if {[lsearch $args unread] >= 0} { return {} }
    set ref {} ; set impl {}
    foreach k {0 1} { foreach j {0 1} { foreach b {0 1} {
        lappend ref  "r:/WORK/$top/slices_${k}/mshrCtl/q_${j}_reg\[$b\]"
        lappend impl "i:/WORK/$top/slices_${k}/u_core/mshrCtl/u_core/q_reg\[$j\]\[$b\]"
    } } }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
