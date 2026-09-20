# VARIANTS: NCBTransactionQueue NCBTransactionQueue_1
# ---------------------------------------------------------------------------
# NCBTransactionQueue 家族钉点文件的**夹具**（scripts/pin_call_equiv.py 用）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 每槽 23 位 = ReturnNID 11（reg [10:0]）+ ReturnTxnID 12（reg [11:0]）；
# 槽数 = golden 里 `reg [10:0] regQueue_<i>_bits_info_ReturnNID;` 的条数。
# ★现数出来是：无后缀 64 槽（1472 点）、_1 才是 32 槽（736 点）★
#   —— 与 fm_eq.tcl 注释里"736 / 1472"的行文顺序相反，照那个顺序会把两个变体装反，
#   而装反之后两边都是正数、都"有个期望值"，闸不会响。
# ---------------------------------------------------------------------------
proc _fx_slots {} {
    global top
    switch -exact -- $top {
        NCBTransactionQueue   { return 64 }
        NCBTransactionQueue_1 { return 32 }
    }
    error "NCBTransactionQueue fixture: unknown variant $top"
}
proc report_unmatched_points {args} {
    global top
    set slots [_fx_slots]
    set ref {} ; set impl {}
    for {set i 0} {$i < $slots} {incr i} {
        for {set b 0} {$b < 11} {incr b} {
            lappend ref  "r:/WORK/$top/regQueue_${i}_bits_info_ReturnNID_reg\[$b\]"
            lappend impl "i:/WORK/$top/u_core/info_q_reg\[$i\]\[return_nid\]\[$b\]"
        }
        for {set b 0} {$b < 12} {incr b} {
            lappend ref  "r:/WORK/$top/regQueue_${i}_bits_info_ReturnTxnID_reg\[$b\]"
            lappend impl "i:/WORK/$top/u_core/info_q_reg\[$i\]\[return_txn_id\]\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
