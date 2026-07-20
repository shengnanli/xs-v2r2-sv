# fm-sidecar-native-v1 原子 emitter(Step 3B, 契约=SIDECAR_SCHEMA.md v7冻结版, 180c1a1)。
# 由 fm_eq.tcl 在 FM_SIDECAR_OUT 非空时 source。职责:
#   ① 运行期 appvar 拦截: source pin/custom Tcl 前扫描其 set_app_var, 不在注册表 → exit 3
#      (拒产 native facts, 非静态 grep——发生在会话运行期)。
#   ② appvar 有效值读回: 全部 pin/custom Tcl 后、verify 前逐项 get_app_var。
#   ③ verify 后全查询→内存解析→JSON→独占 tmp 创建→flush/close→no-force rename;
#      任何错误删 tmp 并 exit 4(无部分产物)。
# 本文件的 bbox 解析器为纯 Tcl(不依赖 fm 命令), 供 tclsh fixture 测试(acceptance gate 1)。

# ---------------- 注册表(与 validator APPVAR_SPEC 键面一致) ----------------
set SIDECAR_APPVAR_REQUIRED {
    verification_verify_unread_compare_points
    verification_verify_matched_unread_compare_points
    verification_verify_unread_bbox_inputs
    verification_verify_matched_unread_bbox_inputs
    verification_verify_unread_tech_cell_pins
    verification_verify_unread_tech_cell_pg_pins
    hdlin_unresolved_modules
    hdlin_interface_only
    verification_merge_duplicated_registers
}
set SIDECAR_APPVAR_OPTIONAL {
    verification_assume_reg_init
    verification_set_undriven_signals
    verification_propagate_const_reg_x
    verification_blackbox_match_mode
}
set SIDECAR_APPVAR_DIAG_ONLY { verification_failing_point_limit }
# 放宽基线(非默认值 → relaxed_appvars; ci 项存小写)
array set SIDECAR_APPVAR_DEFAULT {
    verification_assume_reg_init        auto
    verification_set_undriven_signals   BINARY:X
    verification_propagate_const_reg_x  false
    verification_blackbox_match_mode    any
}
set SIDECAR_EXTRA_KEYS {}   ;# 拦截扫描中发现的注册表内可选键(会被读回并入 entry_appvars)

# ---------------- ① 执行期 appvar 拦截(3B 验收一审重做) ----------------
# 静态正则扫描被裁定不合格(动态命令名/eval/嵌套 source 可绕过, 注释/字符串误报)。
# 改为 rename 原生 set_app_var + wrapper: **每一次真实执行**都经由唯一入口检查——
# `set c set_app_var; $c foo 1`、`eval`、嵌套 source 全部落在同一调用点, 无法绕过。
# 名字在调用时记入 SIDECAR_EXTRA_KEYS(注册表内可选键)→ readback 覆盖, 三方同漏堵死。
proc sidecar_intercept_fail {name} {
    puts "SIDECAR_ERROR: runtime_appvar_intercept var=$name (execution-time wrapper) not-in-registry"
    exit 3
}
proc sidecar_install_appvar_guard {} {
    if {[info commands __sidecar_real_set_app_var] ne ""} return
    rename set_app_var __sidecar_real_set_app_var
    proc set_app_var {args} {
        set name [lindex $args 0]
        set allowed [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_APPVAR_OPTIONAL \
                            $::SIDECAR_APPVAR_DIAG_ONLY]
        if {[lsearch -exact $allowed $name] < 0} {
            sidecar_intercept_fail $name
            return   ;# 仅当 fail 钩子被测试替换为不退出时到达
        }
        if {[lsearch -exact $::SIDECAR_APPVAR_REQUIRED $name] < 0 &&
            [lsearch -exact $::SIDECAR_EXTRA_KEYS $name] < 0} {
            lappend ::SIDECAR_EXTRA_KEYS $name
        }
        uplevel 1 [linsert $args 0 __sidecar_real_set_app_var]
    }
}

# ---------------- ② 有效值读回(verify 前) ----------------
proc sidecar_capture_appvars {} {
    foreach k [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_EXTRA_KEYS] {
        set ::SIDECAR_AV($k) [get_app_var $k]
    }
}

# ---------------- JSON 编码(手写, 转义 \ " 与控制字符) ----------------
proc sidecar_jstr {s} {
    set out ""
    foreach ch [split $s ""] {
        scan $ch %c code
        if {$ch eq "\\"} { append out "\\\\" } \
        elseif {$ch eq "\""} { append out "\\\"" } \
        elseif {$code < 0x20} { append out [format "\\u%04x" $code] } \
        else { append out $ch }
    }
    return "\"$out\""
}
proc sidecar_jlist {lst} {
    set parts {}
    foreach e $lst { lappend parts [sidecar_jstr $e] }
    return "\[[join $parts ,]\]"
}
proc sidecar_jpairs {pairs} {
    # pairs: 已排序的 {ref impl} 列表
    set parts {}
    foreach p $pairs {
        lappend parts "{\"ref_path\":[sidecar_jstr [lindex $p 0]],\"impl_path\":[sidecar_jstr [lindex $p 1]]}"
    }
    return "\[[join $parts ,]\]"
}

# ---------------- bbox 报告解析(纯 Tcl, FM-184 状态机, fail-closed) ----------------
# 返回 6 元素列表: iface_ref iface_impl unres_ref unres_impl empty_ref empty_impl
# 错误以 error 抛出(调用方决定删 tmp/exit)。契约(v7): FM-184 必须存在; FM-249 可共存
# =空集(不得有实例块); 非空不得有 FM-249; flag 只认 i/u/e; Instances N==M 且精确消费 N 条。
# 严格 section/block 状态机(3B 验收一审重写, fail-closed 行分类):
#  - 每个非空行必须命中已知类别之一, 否则 error(顶格游离路径/缩进游离内容/缩进 flag 行
#    全部落此: 不再可能被"宽松扫描"静默跳过)。
#  - block 必须位于 section 内(#### ... LIBRARY - <r|i>: 段头给出 namespace side),
#    路径 side 必须与 section side 一致。
#  - Instances : N of M 要求 N==M 且 **N>0**(0 of 0 的 block 是畸形, 空集=FM-249 形态)。
#  - 精确消费 N 条缩进路径; 路径重复 → error(禁 lsort -unique 修复损坏输入)。
#  - FM-184 必在; FM-249 与任何 block 互斥。
proc sidecar_parse_black_boxes {txt} {
    if {![regexp {\(FM-184\)} $txt]} { error "bbox_report_missing_FM184" }
    set has249 [regexp {\(FM-249\)} $txt]
    array set acc {ir {} ii {} ur {} ui {} er {} ei {}}
    array set seen {}
    set lines [split $txt "\n"]
    set n [llength $lines]
    set saw_block 0
    set cur_side ""      ;# 当前 section 的 namespace side(r|i), 由段头行设置
    set i 0
    while {$i < $n} {
        set ln [string trimright [lindex $lines $i]]
        # ---- 已知非 block 行类别(白名单; 其余非空行一律 error) ----
        if {$ln eq ""} { incr i; continue }
        if {[regexp {^\*+$} $ln]} { incr i; continue }
        if {[regexp {^(Report|Reference|Implementation|Version|Date)\s} $ln]} { incr i; continue }
        if {[regexp {^\s+-\S+$} $ln]} { incr i; continue }  ;# 报告头选项续行(如 " -unresolved")
        if {[regexp {^Information:} $ln]} { incr i; continue }
        if {[string match { _*} $ln] || [string match {|*} $ln]} { incr i; continue }  ;# 图例框
        if {[regexp {^#+$} $ln]} { incr i; continue }
        if {[regexp {^####\s+\S+\s+LIBRARY\s+-\s+([ri]):} $ln -> s]} { set cur_side $s; incr i; continue }
        if {[regexp {^Type\s+Design Name$} $ln]} { incr i; continue }
        if {[regexp {^----\s+-+$} $ln]} { incr i; continue }
        if {[string is integer -strict [string trim $ln]]} { incr i; continue }  ;# redirect 返回值回显
        # ---- block: 顶格 flag 行 ----
        if {[regexp {^(\S{1,2})\s+(\S+)$} $ln -> flag dname]} {
            if {$flag ni {i u e}} { error "bbox_unsupported_flag:${flag}:${dname}" }
            if {$cur_side eq ""} { error "bbox_block_outside_section:${dname}" }
            set saw_block 1
            # 紧随的 Instances : N of M(容空行)
            set j [expr {$i+1}]
            while {$j < $n && [string trim [lindex $lines $j]] eq ""} { incr j }
            if {$j >= $n || ![regexp {^\s+Instances\s*:\s*(\d+)\s+of\s+(\d+)$} \
                              [string trimright [lindex $lines $j]] -> N M]} {
                error "bbox_${dname}_missing_instances_line"
            }
            if {$N != $M} { error "bbox_${dname}_instances_N_ne_M:${N}_of_${M}" }
            if {$N == 0} { error "bbox_${dname}_instances_zero_block" }
            # 分隔行
            set k [expr {$j+1}]
            while {$k < $n && [regexp {^\s*-+\s*$} [lindex $lines $k]]} { incr k }
            # 精确 N 条缩进路径, side 必须==section side, 禁重复
            set got 0
            while {$k < $n && $got < $N} {
                set raw [string trimright [lindex $lines $k]]
                if {[string trim $raw] eq ""} { break }
                if {![regexp {^\s+([ri]):(/\S+)$} $raw -> side rest]} {
                    error "bbox_${dname}_bad_path:[string trim $raw]"
                }
                if {$side ne $cur_side} {
                    error "bbox_${dname}_path_side_mismatch:${side}!=${cur_side}"
                }
                set pl "${side}:${rest}"
                if {[info exists seen($flag$side,$pl)]} { error "bbox_${dname}_duplicate_path:$pl" }
                set seen($flag$side,$pl) 1
                lappend acc($flag$side) $pl
                incr got; incr k
            }
            if {$got != $N} { error "bbox_${dname}_path_count:${got}!=${N}" }
            # 越界路径(缩进或顶格)均须报错: 缩进的落这里, 顶格的落白名单外 error
            if {$k < $n && [regexp {^\s+[ri]:/} [lindex $lines $k]]} {
                error "bbox_${dname}_extra_path_beyond_N"
            }
            set i $k
            continue
        }
        error "bbox_unparsed_line:$ln"
    }
    if {$has249 && $saw_block} { error "bbox_FM249_with_instance_blocks" }
    if {!$has249 && !$saw_block} { error "bbox_nonempty_claim_but_no_blocks" }
    return [list [lsort $acc(ir)] [lsort $acc(ii)] [lsort $acc(ur)] [lsort $acc(ui)] \
                 [lsort $acc(er)] [lsort $acc(ei)]]
}

# ---------------- pair 列表规整 ----------------
proc sidecar_pairs_sorted {raw} {
    # raw: fm -list 返回的 {{ref impl} ...}; 空侧("")拒(matched 语境不应出现)
    set out {}
    foreach p $raw {
        if {[llength $p] != 2} { error "pair_not_2elem:$p" }
        set r [lindex $p 0]; set i [lindex $p 1]
        if {$r eq "" || $i eq ""} { error "pair_empty_side:$p" }
        lappend out [list $r $i]
    }
    return [lsort $out]
}

# ---------------- ③ 汇采与原子写 ----------------
proc sidecar_emit {top} {
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set ::SIDECAR_TMP ""
    if {[catch {sidecar_emit_inner $top} msg]} {
        if {$::SIDECAR_TMP ne ""} { catch {file delete $::SIDECAR_TMP} }
        puts "SIDECAR_ERROR: emit_failed: $msg"
        exit 4
    }
    puts "SIDECAR_NATIVE_FACTS_WRITTEN"
}

proc sidecar_emit_inner {top} {
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::env(FM_RUN_ID)]} { error "missing_FM_RUN_ID" }
    set run_id $::env(FM_RUN_ID)

    # native verdict(只读 app var; 非终态 MATCHED/GUIDE → 拒)
    set nv [get_app_var verification_status]
    switch -- $nv {
        "SUCCEEDED" - "FAILED" - "INCONCLUSIVE" {}
        "NOT RUN" { set nv "NOT_RUN" }
        default { error "nonfinal_verification_status:$nv" }
    }

    # 冻结查询(v7 采集表)
    set l_pass   [report_passing_points -list]
    set l_fail   [report_failing_points -list]
    set l_unver  [report_unverified_points -list]
    set l_abort  [report_aborted_points -list]
    set l_nc_unr [report_matched_points -not_compared -status unread -list]
    set l_m_bbox [report_matched_points -point_type bbox -list]
    set l_m_dv   [report_matched_points -status dont_verify -list]
    set um_ref     [lsort -unique [report_unmatched_points -reference -list]]
    set um_impl    [lsort -unique [report_unmatched_points -implementation -list]]
    set um_unr_r   [lsort -unique [report_unmatched_points -reference -status unread -list]]
    set um_unr_i   [lsort -unique [report_unmatched_points -implementation -status unread -list]]
    set um_dv_r    [lsort -unique [report_unmatched_points -reference -status dont_verify -list]]
    set um_dv_i    [lsort -unique [report_unmatched_points -implementation -status dont_verify -list]]
    set um_bbo_r   [lsort -unique [report_unmatched_points -reference -point_type bbox_output -list]]
    set um_bbo_i   [lsort -unique [report_unmatched_points -implementation -point_type bbox_output -list]]
    set um_bbi_r   [lsort -unique [report_unmatched_points -reference -point_type bbox_input -list]]
    set um_bbi_i   [lsort -unique [report_unmatched_points -implementation -point_type bbox_input -list]]
    set um_pi_r    [lsort -unique [report_unmatched_points -reference -point_type input -list]]
    set um_pi_i    [lsort -unique [report_unmatched_points -implementation -point_type input -list]]

    # gate-3 探针证据(非契约文件): combined unread 查询原始返回
    set fh [open "$out/probe_nc_unread.list" w]
    puts -nonewline $fh $l_nc_unr; close $fh
    # script closure 运行期记账落盘(实际执行的入口/emitter/pin, source 顺序)
    set fh [open "$out/script_closure.list" w]
    foreach f $::SIDECAR_SOURCED { puts $fh $f }
    close $fh

    # black_boxes(FM-184 状态机)
    redirect -variable bb_txt {report_black_boxes}
    lassign [sidecar_parse_black_boxes $bb_txt] if_r if_i un_r un_i em_r em_i

    # dont_verify 用户配置报告: 非空且无法解析 → fail-closed
    redirect -variable dv_txt {report_dont_verify_points}
    set dv_objs {}
    foreach ln [split $dv_txt "\n"] {
        set t [string trim $ln]
        if {$t eq "" || [regexp {^\*+$} $t] || [regexp {^(Report|Reference|Implementation|Version|Date)\s} $t]} continue
        if {[regexp {FM-\d+} $t]} continue
        if {[regexp {^Don't verify points:\s*None$} $t]} continue   ;# 空集标准行(3B 实证)
        if {[string is integer -strict $t]} continue   ;# redirect 含命令返回值回显(3A/3B 实证)
        error "dont_verify_report_unparsed_line:$t"
    }

    # entry appvars(verify 前已捕获)
    if {![info exists ::SIDECAR_AV]} { error "appvars_not_captured_before_verify" }
    set relaxed {}
    foreach k [array names ::SIDECAR_AV] {
        if {[info exists ::SIDECAR_APPVAR_DEFAULT($k)]} {
            set d $::SIDECAR_APPVAR_DEFAULT($k)
            set v $::SIDECAR_AV($k)
            if {$k eq "verification_assume_reg_init"} { set v [string tolower $v] }
            if {$v ne $d} { lappend relaxed $k }
        }
    }
    set av_parts {}
    foreach k [lsort [array names ::SIDECAR_AV]] {
        lappend av_parts "[sidecar_jstr $k]:[sidecar_jstr $::SIDECAR_AV($k)]"
    }

    # JSON 组装(计数=各列表 llength, 同源同单位)
    set J "{"
    append J "\"schema\":\"fm-sidecar-native-v1\","
    append J "\"run_id\":[sidecar_jstr $run_id],\"top\":[sidecar_jstr $top],"
    append J "\"native_verdict\":[sidecar_jstr $nv],"
    append J "\"stats\":{\"passing\":[llength $l_pass],\"failing\":[llength $l_fail],"
    append J "\"unverified\":[llength $l_unver],\"aborted\":[llength $l_abort],"
    append J "\"unread_notcompared\":[llength $l_nc_unr]},"
    append J "\"unmatched\":{\"compare_ref\":[llength $um_ref],\"compare_impl\":[llength $um_impl],"
    append J "\"unread_ref\":[llength $um_unr_r],\"unread_impl\":[llength $um_unr_i],"
    append J "\"bbout_ref\":[llength $um_bbo_r],\"bbout_impl\":[llength $um_bbo_i]},"
    append J "\"objects\":{"
    append J "\"matched_blackbox_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_m_bbox]],"
    append J "\"matched_unread_notcompared_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_nc_unr]],"
    append J "\"matched_dont_verify_pairs\":[sidecar_jpairs [sidecar_pairs_sorted $l_m_dv]],"
    append J "\"interface_only_ref\":[sidecar_jlist $if_r],\"interface_only_impl\":[sidecar_jlist $if_i],"
    append J "\"unresolved_blackbox_ref\":[sidecar_jlist $un_r],\"unresolved_blackbox_impl\":[sidecar_jlist $un_i],"
    append J "\"empty_blackbox_ref\":[sidecar_jlist $em_r],\"empty_blackbox_impl\":[sidecar_jlist $em_i],"
    append J "\"unmatched_ref\":[sidecar_jlist $um_ref],\"unmatched_impl\":[sidecar_jlist $um_impl],"
    append J "\"unmatched_unread_ref\":[sidecar_jlist $um_unr_r],\"unmatched_unread_impl\":[sidecar_jlist $um_unr_i],"
    append J "\"unmatched_dont_verify_ref\":[sidecar_jlist $um_dv_r],\"unmatched_dont_verify_impl\":[sidecar_jlist $um_dv_i],"
    append J "\"unmatched_bbox_output_ref\":[sidecar_jlist $um_bbo_r],\"unmatched_bbox_output_impl\":[sidecar_jlist $um_bbo_i],"
    append J "\"unmatched_bbox_input_ref\":[sidecar_jlist $um_bbi_r],\"unmatched_bbox_input_impl\":[sidecar_jlist $um_bbi_i],"
    append J "\"unmatched_primary_input_ref\":[sidecar_jlist $um_pi_r],\"unmatched_primary_input_impl\":[sidecar_jlist $um_pi_i]},"
    append J "\"qualifications\":{\"dont_verify_objects\":[sidecar_jlist [lsort -unique $dv_objs]],"
    append J "\"elab147\":\[\],"
    append J "\"relaxed_appvars\":[sidecar_jlist [lsort -unique $relaxed]]},"
    append J "\"entry_appvars\":{[join $av_parts ,]}"
    append J "}"

    # 原子写: 独占 tmp 创建 → flush/close → no-force rename
    file mkdir $out
    set ::SIDECAR_TMP "$out/native_facts.json.tmp.[pid]"
    set fh [open $::SIDECAR_TMP {WRONLY CREAT EXCL} 0644]
    puts -nonewline $fh $J
    flush $fh
    close $fh
    set final "$out/native_facts.json"
    if {[file exists $final]} { error "native_facts_already_exists_no_force" }
    file rename $::SIDECAR_TMP $final
    set ::SIDECAR_TMP ""
}
