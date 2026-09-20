# fm_eq_trace.tcl —— 在 tclsh 下把 fm_eq.tcl 跑成**调用序列**，用于两版差分比对。
#
# 为什么要有它（★判据的输入必须独立于被判断的对象★）
# ------------------------------------------------------
# lane 的 receipt 是在各自当时的 scripts/fm_eq.tcl 下产出的；要判"这份 receipt 在
# main 当前闭包下是否仍然成立"，不能靠"我读了 diff，觉得只动了守卫"——那是
# 拿被判断的对象自己当判据。verif/ut/OthersEntry_common/PIN_GUARD_FIX.md 里那条
# lane 已经立过规矩：把命令换成记参数的桩、用 tclsh 真跑两版、逐字节比对
# **实际发生的调用序列**。本文件把同一手法从 fm_pins 推广到 fm_eq 整脚本。
#
# 判据：给定同一组入口环境变量（来自 receipt 自己记录的 proof_config，不是我挑的）
# 与同一组桩返回值，两版 fm_eq.tcl 发出的 FM 命令序列（含顺序、参数、重复）
# 必须逐字节相同。相同 ⇒ 这份 receipt 换到 main 的 fm_eq.tcl 下会走出同一条路径。
#
# 边界（必须诚实写出来）：
#   · 桩返回值是固定的，所以这证明的是"控制流与命令流一致"，不是"FM 会得出同样
#     的结论"。对本轮 25 个 lane 版本够用——它们与 main 的可执行行差异只有 5 类
#     （白名单集合 / 守卫报错文案 / diagnostic-full 标签 / FM_FAILING_LIMIT 块 /
#     set_top_or_die 包装），全都落在控制流上。差异若涉及 appvar 取值，
#     本判据照样会响（取值进 trace）。
#   · 以 FM_SIDECAR_OUT 空跑（SIDECAR_ON=0）。sidecar 分支在 25 个版本里逐行相同，
#     emitter 自身的版本差异由 gen_receipt_harvest.py 另行单独比对，不混在这里。
#
# 用法: FM_TRACE_OUT=<file> FM_TOP=... [其它 FM_*] tclsh scripts/fm_eq_trace.tcl <fm_eq.tcl>

set ::TRACE_FH [open $env(FM_TRACE_OUT) w]

proc ::rec {name arglist} {
    puts $::TRACE_FH "$name\t$arglist"
}

# ---- 桩返回值：两版共用同一份，保证唯一变量是 fm_eq.tcl 本身 ----
set ::CANNED_UNMATCHED "  Ref   DFF      r:/WORK/TOP/foo_1_0_reg\n  Impl  DFF      i:/WORK/TOP/u_core/foo_reg\[1\]\[0\]\n  Ref   DFF      r:/WORK/TOP/bar_reg\n"
set ::CANNED_LIST      {r:/WORK/TOP/dead_reg i:/WORK/TOP/u_core/dead_q_reg}

# FM 的 redirect: 只支持本仓用到的 `redirect -variable NAME {script}` 形式。
proc redirect {args} {
    ::rec redirect $args
    if {[lindex $args 0] eq "-variable"} {
        set vn [lindex $args 1]
        upvar 1 $vn v
        set v $::CANNED_UNMATCHED
        return ""
    }
    return ""
}

# 未定义的命令一律当 FM 动词：记录参数并按名字给固定返回值。
proc unknown {args} {
    set name [lindex $args 0]
    set rest [lrange $args 1 end]
    ::rec $name $rest
    switch -glob -- $name {
        set_top          { return 1 }
        verify           { return 1 }
        set_user_match   { return 1 }
        report_unmatched_points -
        report_matched_points {
            if {[lsearch -exact $rest -list] >= 0} { return $::CANNED_LIST }
            return $::CANNED_UNMATCHED
        }
        find_cells       { return $::CANNED_LIST }
        default          { return "" }
    }
}

rename exit ::real_exit
proc exit {args} {
    ::rec exit $args
    flush $::TRACE_FH
    close $::TRACE_FH
    ::real_exit 0
}

file mkdir fm_work/$env(FM_TOP)

set _script [lindex $argv 0]
# info script 要指向被测文件本身（fm_eq.tcl 用它定位 sidecar/）——source 会自动设置。
if {[catch {source $_script} _err]} {
    ::rec TCL_ERROR [list $_err]
}
if {[info commands ::real_exit] ne ""} {
    catch {flush $::TRACE_FH}
    catch {close $::TRACE_FH}
}
