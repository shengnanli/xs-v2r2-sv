# test_dontverify_parser.tcl —— dont_verify 报告解析的镜像单测。
# 镜像 fm_native_emit.tcl 的 report_dont_verify_points 解析块(约 532-553 行)。
# 权威 e2e 验证是 DataPath 目标重跑; 本测试锁住逻辑分支, 防回归。
# 若 emitter 该块改动, 请同步此镜像并跑 DataPath e2e。

set ::fail 0
proc chk {name expect_err expect_hdr expect_nobj l_m_dv um_dv_r um_dv_i dv_txt} {
    # ---- 以下逻辑逐字镜像 emitter ----
    set dv_objs {}
    foreach p $l_m_dv { foreach q $p { lappend dv_objs $q } }
    foreach q $um_dv_r { lappend dv_objs $q }
    foreach q $um_dv_i { lappend dv_objs $q }
    set dv_nonempty_hdr 0
    set err ""
    if {[catch {
        foreach ln [split $dv_txt "\n"] {
            set t [string trim $ln]
            if {$t eq "" || [regexp {^\*+$} $t] || [regexp {^(Report|Reference|Implementation|Version|Date)[\s:]} $t]} continue
            if {[regexp {FM-\d+} $t]} continue
            if {[regexp {^Don't verify points:\s*None$} $t]} continue
            if {[regexp {^Don't verify points:} $t]} { set dv_nonempty_hdr 1; continue }
            if {[string is integer -strict $t]} continue
            if {$dv_nonempty_hdr} continue
            error "dont_verify_report_unparsed_line:$t"
        }
        if {$dv_nonempty_hdr && [llength $dv_objs] == 0} { error "dont_verify_nonempty_report_but_empty_list" }
    } e]} { set err $e }
    # ---- 断言 ----
    set got_err [expr {$err ne ""}]
    set ok 1
    if {$got_err != $expect_err} { set ok 0 }
    if {!$expect_err} {
        if {$dv_nonempty_hdr != $expect_hdr} { set ok 0 }
        if {[llength [lsort -unique $dv_objs]] != $expect_nobj} { set ok 0 }
    }
    if {$ok} {
        puts "PASS  $name"
    } else {
        puts "FAIL  $name  err=$got_err/$expect_err hdr=$dv_nonempty_hdr nobj=[llength [lsort -unique $dv_objs]] ($err)"
        set ::fail 1
    }
}

# 空集: 标准 None 报告, -list 空 → 无错, 头非空标志=0, 0 对象
chk empty_none          0 0 0 {} {} {} "Don't verify points: None"
# 空集: 报告仅 boilerplate + None(带装饰)
chk empty_none_boiler   0 0 0 {} {} {} "****\nReport : dont_verify\nDon't verify points: None\n0"
# 非空: 头行(无 None) + 点列, -list 有对象(DataPath 情形) → 无错, 头=1;
# 对象计数来自 -list: matched pair 贡献 ref+impl 两个(2) + um_dv_r(1) + um_dv_i(1) = 4
chk nonempty_datapath   0 1 4 {{r:/WORK/DataPath/a i:/WORK/DataPath/a}} {r:/WORK/DataPath/b} {i:/WORK/DataPath/c} \
    "Don't verify points:\n  'r:/WORK/DataPath/a'\n  'r:/WORK/DataPath/b'\n  'i:/WORK/DataPath/c'"
# 非空: 头 + Reference:/Implementation: 分组标签 + 点
chk nonempty_grouped    0 1 2 {} {r:/WORK/X/p} {i:/WORK/X/q} \
    "Don't verify points:\nReference:\n  r:/WORK/X/p\nImplementation:\n  i:/WORK/X/q"
# 头前出现未知垃圾行 → fail-closed(dv_nonempty_hdr 还是0)
chk garbage_before_hdr  1 0 0 {} {} {} "unexpected junk line\nDon't verify points: None"
# 报告称非空但 -list 空 → 捕获不一致, fail-closed
chk nonempty_but_nolist 1 0 0 {} {} {} "Don't verify points:\n  'r:/WORK/Y/z'"

if {$::fail} { puts "\nDONTVERIFY: FAIL"; exit 1 } else { puts "\n6/6 passed"; exit 0 }
