# fm_pins_trace.tcl —— 把一份钉点文件跑成**调用序列**，用于两版差分比对。
#
# 为什么要有它
# ------------
# 关二第 (4) 项原先只比钉点文件的 sha256。字节不同就判红 —— 而本仓已经有过
# 一次**字节变了但钉的点一个没变**的真实改动：
# verif/ut/OthersEntry_common/gen_fm_pins.py 把钉点循环里的
#   `if {[catch {set_user_match ...} _msg]}`  改成  `if {[set_user_match ...]}`
# （旧写法是空守卫：set_user_match 名字不存在时返回 0 而**不抛**，catch 恒 0）。
# 守卫文本变了，`set_user_match` 的参数与顺序一个没动。
# 那条 lane 因此写了 prove_pin_calls_equal.py，把 set_user_match 换成记参数的桩、
# 用 tclsh 真跑两版、逐字节比对实际发生的调用序列，18/18 相同
# （见 verif/ut/OthersEntry_common/PIN_GUARD_FIX.md）。
#
# 本文件把那套手法做成通用的：判据不是"我觉得只动了守卫"，
# ★而是同一组桩返回值下，两版钉点文件实际发出的命令序列逐字节相同。★
# 判据的输入（命令序列）独立于被判断的对象（文件文本）。
#
# 边界（必须写出来）：桩返回值是固定的，所以这证明的是"钉了哪些点、按什么顺序"
# 没变，不是"FM 会接受这些钉点"。对"守卫改写"这类改动够用；
# 若两版钉的点真的不同，本判据必然红。
#
# 用法: FM_PINS_TRACE_OUT=<file> FM_TOP=<top> tclsh scripts/fm_pins_trace.tcl <pins.tcl>

set ::TRACE_FH [open $env(FM_PINS_TRACE_OUT) w]
proc ::rec {name arglist} { puts $::TRACE_FH "$name\t$arglist" }

# 钉点文件引用的只读上下文（fm_eq.tcl 的 sidecar_pin_source 也只传这个）
set top $env(FM_TOP)

# 固定桩返回值：两版共用同一份，保证唯一变量是钉点文件本身。
set ::CANNED_CELLS {r:/WORK/T/a_reg i:/WORK/T/b_reg}
set ::CANNED_RPT   "  Ref   DFF      r:/WORK/T/x_reg\n  Impl  DFF      i:/WORK/T/u_core/x_q_reg\n"

proc redirect {args} {
    ::rec redirect $args
    if {[lindex $args 0] eq "-variable"} {
        upvar 1 [lindex $args 1] v
        set v $::CANNED_RPT
        return ""
    }
    return ""
}

proc unknown {args} {
    set name [lindex $args 0]
    set rest [lrange $args 1 end]
    ::rec $name $rest
    switch -glob -- $name {
        set_user_match { return 1 }
        verify         { return 1 }
        find_cells     { return $::CANNED_CELLS }
        report_unmatched_points -
        report_matched_points {
            if {[lsearch -exact $rest -list] >= 0} { return $::CANNED_CELLS }
            return $::CANNED_RPT
        }
        default { return "" }
    }
}

rename exit ::real_exit
proc exit {args} {
    ::rec exit $args
    flush $::TRACE_FH; close $::TRACE_FH
    ::real_exit 0
}

# 钉点文件自己的 fail-closed 守卫可能 error —— 那也是行为的一部分，记进序列。
# 两版拿到同一组桩返回值，谁 error、在第几步 error，都会逐字节体现在 trace 里。
if {[catch {source [lindex $argv 0]} _err]} {
    ::rec TCL_ERROR [list $_err]
}
catch {flush $::TRACE_FH}
catch {close $::TRACE_FH}
