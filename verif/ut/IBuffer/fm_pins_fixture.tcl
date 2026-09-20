# VARIANTS: IBuffer
# ---------------------------------------------------------------------------
# IBuffer 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 6 个点 = IBufNBank（钉点文件自己把 _expect 声明成 6，并且对下标集合 {0..5}
# 逐条核过；夹具造错了它会当场抛，不会被掩盖）：
#   ref  deqInBankPtr_<b>_flag_reg      <-> impl u_core/deq_inbank_flag_q_reg[<b>]
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    for {set b 0} {$b < 6} {incr b} {
        lappend ref  "r:/WORK/$top/deqInBankPtr_${b}_flag_reg"
        lappend impl "i:/WORK/$top/u_core/deq_inbank_flag_q_reg\[$b\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
