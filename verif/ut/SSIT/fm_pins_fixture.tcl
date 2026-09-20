# VARIANTS: SSIT
# ---------------------------------------------------------------------------
# SSIT 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 91 个点 = 14 个改名寄存器的位宽之和（golden SSIT.sv 现数，width = hi+1）：
#   20+11+5+1+10+10+1+10+10+1+1+5+5+1 = 91
# ---------------------------------------------------------------------------
set _FX_SSIT_MAP {
    resetCounter                20 reset_counter
    resetStepCounter            11 reset_step
    REG                          5 timeout_q
    s1_mempred_update_req_valid  1 s1_valid
    s1_mempred_update_req_ldpc  10 s1_ldpc
    s1_mempred_update_req_stpc  10 s1_stpc
    s2_mempred_update_req_valid  1 s2_valid
    s2_ldSsidAllocate_value     10 s2_ldpc
    s2_stSsidAllocate_value     10 s2_stpc
    s2_loadAssigned              1 s2_load_assigned
    s2_storeAssigned             1 s2_store_assigned
    s2_loadOldSSID               5 s2_load_old_ssid
    s2_storeOldSSID              5 s2_store_old_ssid
    s2_loadStrict                1 s2_load_strict
}
proc report_unmatched_points {args} {
    global top _FX_SSIT_MAP
    set ref {} ; set impl {}
    foreach {g w n} $_FX_SSIT_MAP {
        if {$w == 1} {
            lappend ref  "r:/WORK/$top/${g}_reg"
            lappend impl "i:/WORK/$top/u_core/${n}_reg"
        } else {
            for {set b 0} {$b < $w} {incr b} {
                lappend ref  "r:/WORK/$top/${g}_reg\[$b\]"
                lappend impl "i:/WORK/$top/u_core/${n}_reg\[$b\]"
            }
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
