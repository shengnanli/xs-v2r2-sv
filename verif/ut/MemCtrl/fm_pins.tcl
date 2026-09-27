# MemCtrl / WaitTable FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 本 UT 有两个目标（$top = MemCtrl 或 WaitTable），同一份钉点文件按层次路径通用：
# 可读核把若干 firtool 展平名改成了语义名，按「去掉 u_core 层后的层次路径 + 叶名」一一配对。
#
# 改名表（golden 名 -> 可读核名；括号里是所在实例）：
#   MemCtrl 自己（7 个无复位打拍寄存器，42 位）
#     ssit_io_update_REG_valid            -> ssit_update_q_valid
#     ssit_io_update_REG_ldpc             -> ssit_update_q_ldpc
#     ssit_io_update_REG_stpc             -> ssit_update_q_stpc
#     waittable_io_update_REG_valid       -> waittable_update_q_valid
#     waittable_io_update_REG_waddr       -> waittable_update_q_waddr
#     ssit_io_csrCtrl_REG_lvpred_timeout  -> ssit_timeout_q
#     waittable_io_csrCtrl_REG_lvpred_timeout -> waittable_timeout_q
#   waittable（5 位）：REG -> timeout_q
#   ssit（91 位，与 verif/ut/SSIT/fm_pins.tcl 同一张表，位宽推导见那里）：
#     resetCounter->reset_counter resetStepCounter->reset_step REG->timeout_q
#     s1_mempred_update_req_{valid,ldpc,stpc}->s1_{valid,ldpc,stpc}
#     s2_mempred_update_req_valid->s2_valid s2_ldSsidAllocate_value->s2_ldpc
#     s2_stSsidAllocate_value->s2_stpc s2_loadAssigned->s2_load_assigned
#     s2_storeAssigned->s2_store_assigned s2_loadOldSSID->s2_load_old_ssid
#     s2_storeOldSSID->s2_store_old_ssid s2_loadStrict->s2_load_strict
# 期望配对数（字面整数，钉完再数）：MemCtrl = 42 + 5 + 91 = 138；WaitTable = 5。
# 两个 REG（ssit 的与 waittable 的）叶名相同，靠层次路径区分，所以键是「路径+叶名」不是叶名。
#
# safe interp 约束同 SSIT 那份：只用 report_unmatched_points -list / set_user_match / puts /
# 字符串处理；set_user_match 用返回值判成败；中止用 error（safe interp 里没有 exit）。
array set _mc_rename {
  ssit_io_update_REG_valid                 ssit_update_q_valid
  ssit_io_update_REG_ldpc                  ssit_update_q_ldpc
  ssit_io_update_REG_stpc                  ssit_update_q_stpc
  waittable_io_update_REG_valid            waittable_update_q_valid
  waittable_io_update_REG_waddr            waittable_update_q_waddr
  ssit_io_csrCtrl_REG_lvpred_timeout       ssit_timeout_q
  waittable_io_csrCtrl_REG_lvpred_timeout  waittable_timeout_q
  REG                                      timeout_q
  resetCounter                             reset_counter
  resetStepCounter                         reset_step
  s1_mempred_update_req_valid              s1_valid
  s1_mempred_update_req_ldpc               s1_ldpc
  s1_mempred_update_req_stpc               s1_stpc
  s2_mempred_update_req_valid              s2_valid
  s2_ldSsidAllocate_value                  s2_ldpc
  s2_stSsidAllocate_value                  s2_stpc
  s2_loadAssigned                          s2_load_assigned
  s2_storeAssigned                         s2_store_assigned
  s2_loadOldSSID                           s2_load_old_ssid
  s2_storeOldSSID                          s2_store_old_ssid
  s2_loadStrict                            s2_load_strict
}
# 期望配对数是字面整数：MemCtrl 138（42+5+91）。
# WaitTable 单独做目标时**不钉**：它只有 REG->timeout_q 这一个改名（5 位），实测
# （2026-09-24，fm_work/WaitTable）FM 原生就配上了（ref_unread=0 / impl_unread=0），
# 这里若强求 5 对反而 fail-closed 误停；若哪天原生配不上，strict 终判的 unread 铁律会拦。
set _mc_expect 138
if {$top eq "WaitTable"} {
    puts "MC_PIN_SKIP WaitTable: REG<->timeout_q 由 FM 原生配对（实测 ref_unread=0），本文件不钉"
    return
}

# 把 r:/WORK/<top>/a/u_core/b/x_reg[3] 归一成 {a/b} 与 x_reg[3]（去容器/顶层/u_core 层）
proc _mc_split {p} {
    set s [string trim $p]
    regsub {^[ri]:/WORK/[^/]+/} $s {} s
    set segs {}
    foreach seg [split $s "/"] { if {$seg ne "u_core" && $seg ne ""} { lappend segs $seg } }
    set leaf [lindex $segs end]
    set dir  [join [lrange $segs 0 end-1] "/"]
    return [list $dir $leaf]
}

proc _mc_pin_renamed_regs { } {
    upvar #0 _mc_rename map
    global _mc_expect
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]
    array set impl_lut {}
    foreach ip $impls {
        lassign [_mc_split $ip] d l
        set impl_lut($d/$l) $ip
    }
    puts "MC_PIN_BEGIN $::top expect=$_mc_expect ref_unread=[llength $refs] impl_unread=[llength $impls]"
    set n 0
    set miss 0
    foreach rp $refs {
        lassign [_mc_split $rp] d leaf
        if {![regexp {^(.*)_reg((?:\[\d+\])*)$} $leaf -> stem bits]} { puts "MC_PIN_MISS: $rp (no _reg leaf)"; incr miss; continue }
        if {![info exists map($stem)]} { puts "MC_PIN_MISS: $rp (stem $stem not in table)"; incr miss; continue }
        set key "$d/$map($stem)_reg$bits"
        if {![info exists impl_lut($key)]} { puts "MC_PIN_MISS: $rp wants $key"; incr miss; continue }
        if {![set_user_match $rp $impl_lut($key)]} {
            puts "MC_PIN_FAIL: set_user_match returned 0 for $rp"
            error "MC_PIN_FAIL=$rp"   ;# safe interp 里没有 exit，中止用 error
        }
        unset impl_lut($key)
        incr n
    }
    puts "MC_PIN_END $::top n=$n miss=$miss expect=$_mc_expect"
    if {$miss != 0 || $n != $_mc_expect || [llength $refs] != $_mc_expect} {
        puts "MC_PIN_ERROR: pinned $n miss $miss ref_unread [llength $refs] but expected $_mc_expect"
        error "MC_PIN_COUNT=$n"
    }
    if {$n > 0} { match }
}
_mc_pin_renamed_regs
