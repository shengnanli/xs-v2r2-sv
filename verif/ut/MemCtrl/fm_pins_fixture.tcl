# VARIANTS: MemCtrl
# ---------------------------------------------------------------------------
# MemCtrl/WaitTable 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
# 按 fm_pins.tcl 声明的结构造两侧点名：{层次前缀 golden名 位宽 可读核名}。
#   MemCtrl: 自己 7 个（42 位）+ waittable/REG（5 位）+ ssit/ 14 个（91 位）= 138
#   WaitTable 作为 top 时钉点文件直接 return（原生配对），不需要夹具数据。
# ---------------------------------------------------------------------------
set _FX_MC_MAP {
    {}          ssit_io_update_REG_valid                 1 ssit_update_q_valid
    {}          ssit_io_update_REG_ldpc                 10 ssit_update_q_ldpc
    {}          ssit_io_update_REG_stpc                 10 ssit_update_q_stpc
    {}          waittable_io_update_REG_valid            1 waittable_update_q_valid
    {}          waittable_io_update_REG_waddr           10 waittable_update_q_waddr
    {}          ssit_io_csrCtrl_REG_lvpred_timeout       5 ssit_timeout_q
    {}          waittable_io_csrCtrl_REG_lvpred_timeout  5 waittable_timeout_q
    waittable   REG                                      5 timeout_q
    ssit        resetCounter                            20 reset_counter
    ssit        resetStepCounter                        11 reset_step
    ssit        REG                                      5 timeout_q
    ssit        s1_mempred_update_req_valid              1 s1_valid
    ssit        s1_mempred_update_req_ldpc              10 s1_ldpc
    ssit        s1_mempred_update_req_stpc              10 s1_stpc
    ssit        s2_mempred_update_req_valid              1 s2_valid
    ssit        s2_ldSsidAllocate_value                 10 s2_ldpc
    ssit        s2_stSsidAllocate_value                 10 s2_stpc
    ssit        s2_loadAssigned                          1 s2_load_assigned
    ssit        s2_storeAssigned                         1 s2_store_assigned
    ssit        s2_loadOldSSID                           5 s2_load_old_ssid
    ssit        s2_storeOldSSID                          5 s2_store_old_ssid
    ssit        s2_loadStrict                            1 s2_load_strict
}
set _FX_WT_MAP {
    {}          REG                                      5 timeout_q
}
proc report_unmatched_points {args} {
    global top _FX_MC_MAP _FX_WT_MAP
    set ref {} ; set impl {}
    if {$top eq "WaitTable"} { set m $_FX_WT_MAP } else { set m $_FX_MC_MAP }
    foreach {pre g w n} $m {
        if {$pre eq ""} { set rp "r:/WORK/$top/" ; set ip "i:/WORK/$top/u_core/" } \
        else            { set rp "r:/WORK/$top/$pre/" ; set ip "i:/WORK/$top/u_core/$pre/u_core/" }
        if {$w == 1} {
            lappend ref  "${rp}${g}_reg"
            lappend impl "${ip}${n}_reg"
        } else {
            for {set b 0} {$b < $w} {incr b} {
                lappend ref  "${rp}${g}_reg\[$b\]"
                lappend impl "${ip}${n}_reg\[$b\]"
            }
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
