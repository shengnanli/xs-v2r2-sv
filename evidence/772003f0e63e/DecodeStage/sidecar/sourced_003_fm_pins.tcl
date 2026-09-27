# DecodeStage FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 为什么需要：golden 里 XSPerfAccumulate("frontend_stall_cycle"/"backend_stall_cycle") 的
# GatedValidRegNext 各多产生一份与 frontendStall_last_REG / backendStall_last_REG 打拍相同
# 的寄存器（golden `last_REG` / `last_REG_1`），只喂 last_probe / last_1_probe 观测线，
# 本配置下无读者（cone-dead）。可读核对称保留（xs_DecodeStage_core 的
# frontendStall_probe_q / backendStall_probe_q，同异步复位 0、同次态），但名字不同，
# fm_eq.tcl 的 auto_match_flattened_arrays 配不上，由本文件按规则 set_user_match。
# 钉上后它们成 matched-unread，由 vmucp（Makefile 里 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true，
# 白名单 verif/fm_target_config/DecodeStage.tcl）**实际比较** —— 这是加强，不是放过。
#
# 期望数量 2 是机械推导的：两个 perf 事件各 1 位。
# 写法照 verif/ut/Bitmap/fm_pins.tcl：跑在 sidecar 的 safe child interp 里（无 file/redirect/exit），
# 现场读回真实点名，用 set_user_match 的返回值判成败，末尾 fail-closed 全用 `error`。
# ---------------------------------------------------------------------------
proc _ds_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

proc _ds_pin_dead_probe_regs { } {
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    array set impl_lut {}
    foreach ip $impls { set impl_lut([_ds_leaf $ip]) $ip }

    set _expect 2
    puts "DS_PIN_BEGIN DecodeStage ref_unread=[llength $refs] impl_unread=[llength $impls] expect=$_expect"

    set n 0
    set miss 0
    set foreign 0
    foreach rpath $refs {
        set leaf [_ds_leaf $rpath]
        set want ""
        if {$leaf eq "last_REG_reg"} {
            set want "frontendStall_probe_q_reg"
        } elseif {$leaf eq "last_REG_1_reg"} {
            set want "backendStall_probe_q_reg"
        } else {
            puts "DS_PIN_FOREIGN: $rpath 不属于 last_REG/last_REG_1"
            incr foreign
            continue
        }
        if {![info exists impl_lut($want)]} {
            puts "DS_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "DS_PIN_FAIL: set_user_match returned 0 for $rpath"
            error "DS_PIN_MISS=$rpath"
        }
        puts "DS_PIN: $rpath <-> $impl_lut($want)"
        unset impl_lut($want)
        incr n
    }
    puts "DS_PIN_END DecodeStage n=$n miss=$miss foreign=$foreign expect=$_expect"
    # fail-closed：钉不上 / 有本族之外的 ref 死点 / 数量不对，都在这里停住。
    if {$miss != 0}    { error "DS_PIN_NO_PARTNER=$miss" }
    if {$foreign != 0} { error "DS_PIN_FOREIGN_REF_UNREAD=$foreign" }
    if {$n != $_expect} {
        puts "DS_PIN_ERROR: pinned $n but expected $_expect"
        error "DS_PIN_COUNT=$n"
    }
    if {$n > 0} { match }
}

_ds_pin_dead_probe_regs
