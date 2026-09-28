# MEFreeList FM 钉点 —— **只消命名鸿沟**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 为什么需要：golden 的 530 位 debug 影子寄存器(debugArchHeadPtr 两级 9+9 位、
# debugArchRAT 两级 32×8+32×8 位)综合口径下没有可观测扇出，是死位；重写核按同名同宽
# 同源复刻(rtl/backend/MEFreeList.sv 第 9 节)。死位没有锥，FM 的签名分析配不上它们；
# 而 scripts/fm_eq.tcl 的 auto_match_flattened_arrays 只看 report_unmatched_points 的
# 默认报告，unread 类的点不在里面(2026-09-27 实测：开 vmucp 前后都是
# `530(530) Unmatched reference(implementation) unread points`，AUTO_MATCH 0 行)。
# 所以这里按 SSIT 先例现场读回两侧 unread 点、按机械规则配对：
#   ref  debugArchRAT_REG_<i>_reg[<b>]      <-> impl debugArchRAT_REG_reg[<i>][<b>]
#   ref  debugArchRAT_<i>_reg[<b>]          <-> impl debugArchRAT_reg[<i>][<b>]
#   ref  debugArchHeadPtr_REG_flag_reg      <-> impl 同名(核里为对齐已拆成 _flag/_value 标量)
#   ref  debugArchHeadPtr_REG_value_reg[<b>]<-> impl 同名
#   ref  debugArchHeadPtr_{flag,value}...   <-> impl 同名
# 配对只看叶名，不把层次路径写死：本文件在 MEFreeList 单证(/WORK/MEFreeList/ vs
# /WORK/MEFreeList/u_core/)与 Rename 整证(多一层 intFreeList/…)下都能用。
#
# ★期望值 530 是机械推导的★：逐个从 G1 golden 的 `reg [hi:0] <名>;` 现数：
#   debugArchHeadPtr_REG_flag 1 + debugArchHeadPtr_REG_value 8 + debugArchHeadPtr_flag 1
#   + debugArchHeadPtr_value 8 + debugArchRAT_REG_0..31 32×8 + debugArchRAT_0..31 32×8 = 530。
#
# 三条实测约束(照 SSIT 写)：
# (1) 本文件跑在 sidecar 的 safe child interp 里，只能用白名单命令(report_unmatched_points
#     -list / set_user_match / match / puts / error …)，没有 redirect / file。
# (2) set_user_match 从不抛异常：返回 1 成功、0 失败(并往 fm.log 写行首 Error:)。用返回值判。
# (3) 中止一律用 error，不用 exit(safe interp 藏了 exit)。
# 四道 fail-closed：每次 set_user_match 必须返回 1；miss 必须为 0；ref 侧 unread 总数必须
# 等于 530；配对数必须等于 530。
# ---------------------------------------------------------------------------

proc _mefl_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

# ref 叶名 → impl 叶名(配不上返回空串)
proc _mefl_partner {leaf} {
    if {[regexp {^(debugArchRAT(?:_REG)?)_(\d+)_reg\[(\d+)\]$} $leaf -> stem i b]} {
        return "${stem}_reg\[$i\]\[$b\]"
    }
    if {[regexp {^debugArchHeadPtr(?:_REG)?_(?:flag|value)_reg(?:\[\d+\])?$} $leaf]} {
        return $leaf
    }
    return ""
}

proc _mefl_pin_debug_regs { } {
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    array set impl_lut {}
    foreach ip $impls { set impl_lut([_mefl_leaf $ip]) $ip }

    set _expect 530
    puts "MEFL_PIN_BEGIN MEFreeList expect=$_expect"

    set n 0
    set miss 0
    foreach rpath $refs {
        set want [_mefl_partner [_mefl_leaf $rpath]]
        if {$want eq ""} {
            puts "MEFL_PINS_MISS: $rpath 不属于 debug 影子寄存器四族"
            incr miss
            continue
        }
        if {![info exists impl_lut($want)]} {
            puts "MEFL_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "MEFL_PIN_FAIL: set_user_match returned 0 for $rpath"
            error "MEFL_PIN_MISS=$rpath"
        }
        unset impl_lut($want)
        incr n
    }
    puts "MEFL_PIN_END MEFreeList n=$n miss=$miss expect=$_expect"
    puts "MEFL_PINS_TRIED: ref_unread=[llength $refs] impl_unread=[llength $impls] tried=$n miss=$miss"
    if {$miss != 0} { error "MEFL_PIN_NO_PARTNER=$miss" }
    if {[llength $refs] != $_expect} {
        puts "MEFL_PIN_ERROR: ref unread points [llength $refs] but expected $_expect"
        error "MEFL_PIN_REF_COUNT=[llength $refs]"
    }
    if {[llength $impls] != $_expect} {
        puts "MEFL_PIN_ERROR: impl unread points [llength $impls] but expected $_expect"
        error "MEFL_PIN_IMPL_COUNT=[llength $impls]"
    }
    if {$n != $_expect} {
        puts "MEFL_PIN_ERROR: pinned $n but expected $_expect"
        error "MEFL_PIN_COUNT=$n"
    }
    if {$n > 0} { match }
}

_mefl_pin_debug_regs
