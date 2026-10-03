# =============================================================================
# fm_pins.tcl —— HPerfCounter_21 / HPerfMonitor_3 匹配后钉点（只 set_user_match，不约束 ref）
#
# 要钉的东西：每个计数器里三个 5 位算子寄存器 event_op_0/1/2 与 event_op_2_reg 的 [4:3]。
#   combine 只看算子低 3 位，[4:3] 在 golden 与重写件里同为 cone-dead（未读）。
#   可读核已把寄存器名改成与 golden 同名（见 rtl/common/HPerfCounter_21.sv S1 段注释），
#   所以 HPerfCounter_21 单独跑时 FM 按名就能全配上，这里只断言"没有剩下未配的"。
#   HPerfMonitor_3 里实例路径不同：golden 平铺 perfEvents_hpc / perfEvents_hpc_<N>，
#   重写件是 u_core/g_cnt[<N>].perfEvents_hpc/u_core —— 叶名相同，只差路径，按下式一一钉：
#     r:/WORK/HPerfMonitor_3/perfEvents_hpc[_N]/<leaf>
#       -> i:/WORK/HPerfMonitor_3/u_core/g_cnt[N].perfEvents_hpc/u_core/<leaf>   （无 _N 即 N=0）
# 期望数机械推导：8 个计数器 × 4 个寄存器 × 2 位 = 64；HPerfCounter_21 = 0。
# fail-closed：缺伴 / 数目不对 / set_user_match 失败 都 error 停住。
# =============================================================================

proc _hperf_pin_dead_op_bits { } {
    # 钉点文件在 safe interp 里跑，读不到 env；fm_eq.tcl 只把 top 的值传进来
    set top $::top
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    if {$top eq "HPerfCounter_21"} {
        set _expect 0
    } elseif {$top eq "HPerfMonitor_3"} {
        set _expect 64
    } else {
        error "HPERF_PIN_UNKNOWN_TOP=$top"
    }
    puts "HPERF_PIN_BEGIN $top expect=$_expect ref_unread=[llength $refs] impl_unread=[llength $impls]"

    array set impl_lut {}
    foreach ip $impls { set impl_lut($ip) 1 }

    set n 0
    set miss 0
    foreach rpath $refs {
        set pat "^r:/WORK/HPerfMonitor_3/perfEvents_hpc(_(\\d+))?/(event_op_\[012\]_reg|event_op_2_reg_reg)\\\[(\[34\])\\\]\$"
        if {![regexp $pat $rpath -> _ idx reg bit]} {
            puts "HPERF_PIN_UNEXPECTED: $rpath 不属于算子死位族"
            incr miss
            continue
        }
        if {$idx eq ""} { set idx 0 }
        set want "i:/WORK/HPerfMonitor_3/u_core/g_cnt\[$idx\].perfEvents_hpc/u_core/$reg\[$bit\]"
        if {![info exists impl_lut($want)]} {
            puts "HPERF_PIN_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {![set_user_match $rpath $want]} {
            error "HPERF_PIN_FAIL=$rpath"
        }
        unset impl_lut($want)
        incr n
    }
    puts "HPERF_PIN_END $top n=$n miss=$miss expect=$_expect impl_left=[array size impl_lut]"
    if {$miss != 0}                     { error "HPERF_PIN_NO_PARTNER=$miss" }
    if {[llength $refs] != $_expect}    { error "HPERF_PIN_REF_COUNT=[llength $refs]" }
    if {[llength $impls] != $_expect}   { error "HPERF_PIN_IMPL_COUNT=[llength $impls]" }
    if {$n != $_expect}                 { error "HPERF_PIN_COUNT=$n" }
    if {[array size impl_lut] != 0}     { error "HPERF_PIN_IMPL_LEFT=[array size impl_lut]" }
}

_hperf_pin_dead_op_bits
