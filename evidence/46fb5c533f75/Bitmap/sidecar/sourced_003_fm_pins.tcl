# Bitmap FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 为什么需要：条目池的 id 字段是 bMemID=4 位（golden `reg [3:0] entries_<i>_id`），
# 但请求 id 只有 3 位（`io_req_bits_id[2:0]`），golden 写进去的永远是
# `{1'h0, io_req_bits_id}`（Bitmap.sv:1517），而唯一的读者 `io_resp_bits_id` 只取
# `[2:0]`（Bitmap.sv:3328）。所以 **bit 3 在两侧都是 cone-dead 的死位**，没有签名可比；
# 可读核把 8 个条目的 id 放在非打包数组里（`entries_id_reg[<i>][3]`），golden 是
# 展平名（`entries_<i>_id_reg[3]`），下标在词干中间，fm_eq.tcl 的
# auto_match_flattened_arrays（只认 `<名>_<i>_reg` 尾缀形）配不上。
# 实测（2026-09-22 首跑 evidence/36600b5a07b8/Bitmap）：native SUCCEEDED / passing 1761 /
# failing 0 / unmatched 0，unread_ref 8 / unread_impl 8 —— 恰好就是这 8 位，
# 逐条列在 unread_points.txt 里。钉上后它们成 matched_nc，由 vmucp（Makefile 里
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true，白名单 verif/fm_target_config/Bitmap.tcl）
# **实际比较**——这是加强，不是放过。
#
# 期望数量 8 是机械推导的：8 个条目 × 1 位（bit 3）。
# 写法照 verif/ut/SSIT/fm_pins.tcl：跑在 sidecar 的 safe child interp 里（无 file/redirect/exit），
# 用 report_unmatched_points -list 现场读回真实点名，用 set_user_match 的**返回值**判成败，
# 末尾四道 fail-closed 全用 `error`。
# ---------------------------------------------------------------------------
proc _bitmap_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

proc _bitmap_pin_dead_id_bit3 { } {
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    array set impl_lut {}
    foreach ip $impls { set impl_lut([_bitmap_leaf $ip]) $ip }

    set _expect 8
    puts "BITMAP_PIN_BEGIN Bitmap expect=$_expect"

    set n 0
    set miss 0
    foreach rpath $refs {
        set leaf [_bitmap_leaf $rpath]
        # golden 叶名 entries_<i>_id_reg[3]  ->  可读核 entries_id_reg[<i>][3]
        if {![regexp {^entries_(\d+)_id_reg\[3\]$} $leaf -> idx]} { continue }
        set want "entries_id_reg\[$idx\]\[3\]"
        if {![info exists impl_lut($want)]} {
            puts "BITMAP_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "BITMAP_PIN_FAIL: set_user_match returned 0 for $rpath"
            error "BITMAP_PIN_MISS=$rpath"
        }
        unset impl_lut($want)
        incr n
    }
    puts "BITMAP_PIN_END Bitmap n=$n miss=$miss expect=$_expect"
    puts "BITMAP_PINS_TRIED: ref_unread=[llength $refs] impl_unread=[llength $impls] tried=$n miss=$miss"
    # fail-closed：钉不上 / 少钉 / 多出一族，都在这里停住。
    if {$miss != 0} { error "BITMAP_PIN_NO_PARTNER=$miss" }
    if {[llength $refs] != $_expect} {
        puts "BITMAP_PIN_ERROR: ref unread points [llength $refs] but expected $_expect"
        error "BITMAP_PIN_REF_COUNT=[llength $refs]"
    }
    if {$n != $_expect} {
        puts "BITMAP_PIN_ERROR: pinned $n but expected $_expect (8 entries x id bit 3)"
        error "BITMAP_PIN_COUNT=$n"
    }
    if {$n > 0} { match }
}

_bitmap_pin_dead_id_bit3
