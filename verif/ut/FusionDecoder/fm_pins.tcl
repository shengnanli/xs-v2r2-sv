# FusionDecoder FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 为什么需要：golden 每对指令有两个 RegNext(fire) 打拍寄存器 —— `lastFire`（给
# case_*_i perf 计数器）与 `REG`（给 fused_instr perf 计数器），本配置下 perf 段无任何
# 读者，两者都是 cone-dead。可读核对称保留（xs_FusionDecoder_core 的 lastFire[i] /
# fireDelayed_perf[i]），但 golden 是展平名（第 0 对无后缀：lastFire_reg / REG_reg；
# 其余 lastFire_<i>_reg / REG_<i>_reg），可读核是数组名（lastFire_reg[<i>] /
# fireDelayed_perf_reg[<i>]）。fm_eq.tcl 的 auto_match_flattened_arrays 只能配上
# `lastFire_<i>_reg`（i>=1）这一族；第 0 对（无后缀）与 REG 一族（词干不同）配不上，
# 由本文件按规则 set_user_match。钉上后它们成 matched-unread，由 vmucp（Makefile 里
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true，白名单 verif/fm_target_config/FusionDecoder.tcl）
# **实际比较** —— 这是加强，不是放过。
#
# 死位总数是机械推导的：5 对 × 2 个 = 10；本文件只钉 auto match 剩下的那部分，
# 并要求钉完之后 ref 侧不再有任何未匹配的 unread 点（不许有本族之外的漏网点）。
# 写法照 verif/ut/Bitmap/fm_pins.tcl：跑在 sidecar 的 safe child interp 里
# （无 file/redirect/exit），现场读回真实点名，用 set_user_match 的返回值判成败，
# 末尾 fail-closed 全用 `error`。
# ---------------------------------------------------------------------------
proc _fd_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

proc _fd_pin_dead_perf_regs { } {
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    array set impl_lut {}
    foreach ip $impls { set impl_lut([_fd_leaf $ip]) $ip }

    puts "FD_PIN_BEGIN FusionDecoder ref_unread=[llength $refs] impl_unread=[llength $impls]"

    set n 0
    set miss 0
    set foreign 0
    foreach rpath $refs {
        set leaf [_fd_leaf $rpath]
        set want ""
        if {$leaf eq "lastFire_reg"} {
            set want "lastFire_reg\[0\]"
        } elseif {[regexp {^lastFire_(\d+)_reg$} $leaf -> idx]} {
            set want "lastFire_reg\[$idx\]"
        } elseif {$leaf eq "REG_reg"} {
            set want "fireDelayed_perf_reg\[0\]"
        } elseif {[regexp {^REG_(\d+)_reg$} $leaf -> idx]} {
            set want "fireDelayed_perf_reg\[$idx\]"
        } else {
            puts "FD_PIN_FOREIGN: $rpath 不属于 lastFire/REG 两族"
            incr foreign
            continue
        }
        if {![info exists impl_lut($want)]} {
            puts "FD_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "FD_PIN_FAIL: set_user_match returned 0 for $rpath"
            error "FD_PIN_MISS=$rpath"
        }
        puts "FD_PIN: $rpath <-> $impl_lut($want)"
        unset impl_lut($want)
        incr n
    }
    puts "FD_PIN_END FusionDecoder n=$n miss=$miss foreign=$foreign"
    # fail-closed：钉不上 / 有本族之外的 ref 死点 / 钉多于 10 个，都在这里停住。
    if {$miss != 0}    { error "FD_PIN_NO_PARTNER=$miss" }
    if {$foreign != 0} { error "FD_PIN_FOREIGN_REF_UNREAD=$foreign" }
    if {$n > 10}       { error "FD_PIN_COUNT_OVER=$n" }
    if {$n > 0} { match }
}

_fd_pin_dead_perf_regs
