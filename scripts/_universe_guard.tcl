# _universe_guard.tcl —— universe 提取脚本共用的 fail-closed 校验。
#
# 教训（2026-09-12）：两个 universe 提取脚本的第一版都
#   (a) 没有 set_mismatch_message_filter，导致 link 被 FM-262 拒绝、set_top FM-156 失败；
#   (b) 不检查任何返回值，失败后照样打印 "done" 并退出 0。
# 结果一个跑了 2.67 小时的任务被我误判为成功，报给用户的也是错的。
# 结论与 codex 反复强调的同一条：**任何"做了就走"的操作都必须带断言**。

# ★ 只用于 universe 提取 ★
# FMR_ELAB-147 = "Index may take values outside array bound"。
# golden 的行为级 RAM（如 dt_pcTransType_160x2 / stateBankTags_320x3）用 N 位地址寻址
# 非 2 幂深度的数组（`Memory[R0_addr]`）；指针在 RTL 层可证不越界，但 Formality 静态
# elaboration 证不了，于是抛 ELAB-147，并在 link 阶段升级为 unsuppressed error →
# set_top 失败（FM-262 → FM-156）→ 整个提取中止。
#
# universe 提取只要 hierarchy、**不做任何等价判定**，故降级为 warn 是安全的。
# ☠ 严禁把这条 filter 复制进任何 signoff 配置。signoff 下越界索引的解释会真实影响
#   比对结论；那里的正解是**对称黑盒**——把存储折叠成与 golden 同名的厂商 RAM 叶子，
#   两侧都不提供 body，阵列根本不 elaborate（见 verif/ut/L2TlbMissQueue 的做法）。
#   scripts/fm_verdict.py 已把 FMR_ELAB-147 列为 qualification 痕迹检测项，
#   signoff 日志里一旦出现会被判定逻辑抓到。
#
# 教训：这个 ELAB-147 我在 L2TlbMissQueue 单目标上早已诊断并解决过，却没把结论带到
# 芯片级 universe 脚本里 —— "局部解了没有推广" 的同类错误。
proc u_allow_x_interpretation {} {
    set_mismatch_message_filter -warn FMR_ELAB-147
}

# set_top 必须真成功；失败立即非零退出，绝不继续往下走。
proc u_set_top {top} {
    if {[catch {set_top $top} rc]} {
        puts "UNIVERSE_GUARD: FAIL set_top $top 抛异常: $rc"
        exit 2
    }
    if {$rc != 1} {
        puts "UNIVERSE_GUARD: FAIL set_top $top 返回 $rc（期望 1）"
        exit 2
    }
    puts "UNIVERSE_GUARD: set_top $top OK"
}

# 报告校验：错误标记一律判失败；hierarchy/designs 还要求体积非平凡
# （blackboxes 报告合法地可以很短，故不设体积下限）。
proc u_check_reports {outdir} {
    set ok 1
    foreach {f minsize} [list xstop_designs.txt 10000 \
                              xstop_hierarchy.txt 10000 \
                              xstop_blackboxes.txt 0] {
        set p $outdir/$f
        if {![file exists $p]} { puts "UNIVERSE_GUARD: 缺文件 $f"; set ok 0; continue }
        set fh [open $p r]; set t [read $fh]; close $fh
        foreach bad {FM-008 FM-204 FM-156 FM-262 FMR_ELAB-147} {
            if {[string first "($bad)" $t] >= 0} {
                puts "UNIVERSE_GUARD: $f 含错误标记 ($bad)"; set ok 0
            }
        }
        set n [string length $t]
        if {$n < $minsize} {
            puts "UNIVERSE_GUARD: $f 仅 $n 字节（下限 $minsize），疑似空报告"; set ok 0
        }
    }
    if {!$ok} { puts "UNIVERSE_GUARD: FAIL 报告校验未通过"; exit 3 }
    puts "UNIVERSE_GUARD: 三份报告校验通过"
}

# 生成三份报告。★report_hierarchy 必须显式传 designID★：
# set_top 设的是 reference design，不是 current_design，report_hierarchy 默认作用于
# 后者，于是即便 set_top 成功也会报 "The current design is not set (FM-008)"。
# 实测（bbox2, 3.34 小时）：set_top OK、report_designs 2.2MB、report_black_boxes 419 条
# 都正常，唯独 hierarchy 只有 334 字节的错误占位。工具自带 help 确认
# `report_hierarchy [-level N] [designID]` 接受设计名，故显式传入。
proc u_write_reports {outdir top} {
    current_design $top
    redirect $outdir/xstop_designs.txt    {report_designs}
    redirect $outdir/xstop_hierarchy.txt  "report_hierarchy $top"
    redirect $outdir/xstop_blackboxes.txt {report_black_boxes}
}
