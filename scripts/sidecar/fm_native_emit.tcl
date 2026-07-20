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

# ---------------- ① 执行期 appvar 拦截(3B 验收二审重做) ----------------
# 一审 rename+wrapper 被裁定可绕过(暴露的原生别名 __sidecar_real_set_app_var 可直呼,
# 生效却不进 readback/history)。二审改为 **execution trace 加在命令本身**:
#   trace add execution set_app_var enter —— 无论 wrapper/别名/动态名/eval/嵌套 source,
#   任何真实执行都触发 trace(不再存在暴露的旁路命令)。
# 并加 phase/写历史约束:
#   - 首次 match 之后禁止再改 proof appvar(phase_violation)——堵"先放宽、match、再恢复"。
#   - 同名变值重写 → 拒(rewrite_changed_value); 同值幂等重写放行。
#   - readback(capture)时逐项核对 get_app_var == 写历史末值(history_mismatch 拒)。
proc sidecar_intercept_fail {reason} {
    puts "SIDECAR_ERROR: runtime_appvar_intercept $reason (execution-trace)"
    exit 3
}
proc sidecar_appvar_trace {cmd op} {
    set name [lindex $cmd 1]; set val [lindex $cmd 2]
    set allowed [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_APPVAR_OPTIONAL \
                        $::SIDECAR_APPVAR_DIAG_ONLY]
    if {[lsearch -exact $allowed $name] < 0} {
        sidecar_intercept_fail "not-in-registry:$name"; return
    }
    if {$::SIDECAR_PHASE ne "setup"} {
        sidecar_intercept_fail "phase_violation_after_match:$name"; return
    }
    if {[info exists ::SIDECAR_AV_HISTORY($name)] && $::SIDECAR_AV_HISTORY($name) ne $val} {
        sidecar_intercept_fail "rewrite_changed_value:$name"; return
    }
    set ::SIDECAR_AV_HISTORY($name) $val
    if {[lsearch -exact $::SIDECAR_APPVAR_REQUIRED $name] < 0 &&
        [lsearch -exact $::SIDECAR_EXTRA_KEYS $name] < 0} {
        lappend ::SIDECAR_EXTRA_KEYS $name
    }
}
proc sidecar_match_trace {cmd op} { set ::SIDECAR_PHASE matched }
# 三审: script closure 记账 = **执行时刻字节快照**(消除"执行A、事后哈希B"的 TOCTOU):
# 每次 source 在 enter-trace 时把目标文件字节原样拷入 $FM_SIDECAR_OUT/sourced_NNN_<name>,
# 并即时追加 script_closure.list 行(orig<TAB>snapshot)。runner 只对快照字节做 digest。
# 拒产会话(拦截 exit)也已留下入口/emitter/pin 的快照。
proc sidecar_sha256_hex {bytes} {
    # 依赖 fm_shell 的 sha256 (Synopsys tcl 内置); tclsh 测试环境用 fallback。
    if {[info commands ::sha2::sha256] ne ""} { return [::sha2::sha256 -hex $bytes] }
    if {[info commands ::sha256] ne ""} { return [::sha256 $bytes] }
    # fallback: 系统 sha256sum(父解释器; 临时文件路由到证据目录或 /tmp)
    set dir "/tmp"
    if {[info exists ::env(FM_SIDECAR_OUT)] && $::env(FM_SIDECAR_OUT) ne ""} { set dir $::env(FM_SIDECAR_OUT) }
    set tmp [file join $dir .sha_[pid]_[incr ::SIDECAR_SHA_SEQ]]
    set fh [open $tmp wb]; fconfigure $fh -translation binary; puts -nonewline $fh $bytes; close $fh
    set rc [catch {exec sha256sum $tmp} out]
    file delete $tmp
    if {$rc} { error "sha256_unavailable" }
    return [lindex $out 0]
}
proc sidecar_snapshot_buffer {origpath rawbytes} {
    # 五审: 原样字节(open rb 读入的原始 bytes)落盘并入台账; runner 对**同一原始字节**
    # 做 digest。台账记 {orig, snap, sha256(原始字节)} 全内容, 顺序+唯一(capture 前精确核对)。
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::SIDECAR_SRC_SEQ]} { set ::SIDECAR_SRC_SEQ 0 }
    set snap [format "sourced_%03d_%s" $::SIDECAR_SRC_SEQ [file tail $origpath]]
    incr ::SIDECAR_SRC_SEQ
    set fh [open "$out/$snap" wb]
    fconfigure $fh -translation binary
    puts -nonewline $fh $rawbytes
    close $fh
    set hex [sidecar_sha256_hex $rawbytes]
    set fh [open "$out/script_closure.list" a]
    puts $fh "$origpath\t$snap\t$hex"; close $fh
    lappend ::SIDECAR_LEDGER [list $origpath $snap $hex]
    lappend ::SIDECAR_SOURCED $origpath
}
proc sidecar_register_script {path} {
    set p [file normalize $path]
    # 五审: open rb 原样读取原始字节(不经 locale 文本编码); 执行时按 UTF-8 解码同一缓冲。
    set in [open $p rb]; set rawbytes [read $in]; close $in
    sidecar_snapshot_buffer $p $rawbytes
    return $rawbytes
}
proc sidecar_source_trace {cmd op} {
    # 三审: 解析两种合法形式 `source file` / `source -encoding enc file`(文件名=末参),
    # 不再固定取参数1(那会把 -encoding 记成路径)。(父层 source 仅入口自身使用)
    sidecar_register_script [lindex $cmd end]
}
# ---------------- 四审: pin/custom Tcl 进受限 child interpreter ----------------
# 同解释器执行被裁定可拆除 guard(set ::SIDECAR_PHASE / trace remove)并覆盖快照。
# 现 pin 代码在 **safe child interp** 中执行: 无 file/open/exec/source 权限, 拿不到
# 父层 globals/trace/rename 管理权与证据目录; 白名单 alias 只暴露
# set_user_match / set_app_var(父层 trace 照常拦)/ get_app_var / puts。
# 受控 source: **一次读取字节 → 快照 → 在 child 执行同一缓冲**(不再二次打开原路径);
# 嵌套 source 经 alias 走同一受控入口。
proc sidecar_pin_source {path} {
    if {![info exists ::SIDECAR_PIN_INTERP]} {
        set ::SIDECAR_PIN_INTERP [interp create -safe]
        # 白名单 alias: 只暴露证明相关的 fm 命令(safe interp 已隐藏 file/open/exec/socket)
        foreach c {set_user_match set_app_var get_app_var puts report_unmatched_points \
                   report_matched_points set_constant remove_constant} {
            if {[info commands $c] ne ""} {
                interp alias $::SIDECAR_PIN_INTERP $c {} $c
            }
        }
        interp alias $::SIDECAR_PIN_INTERP source {} sidecar_pin_source
        # pin 代码引用的只读上下文变量(top 等); 只传值, 不给父层命名空间访问权
        if {[uplevel #0 {info exists top}]} {
            interp eval $::SIDECAR_PIN_INTERP [list set top [uplevel #0 {set top}]]
        }
    }
    set p [file normalize $path]
    # 五审: open rb 原样字节 → snapshot(digest 绑原始字节) → **同一缓冲**按 UTF-8 解码后执行
    set in [open $p rb]; set rawbytes [read $in]; close $in
    sidecar_snapshot_buffer $p $rawbytes
    interp eval $::SIDECAR_PIN_INTERP [encoding convertfrom utf-8 $rawbytes]
}
proc sidecar_verify_snapshot_ledger {} {
    # 五审: 精确核对 {orig, snap, hash} **全内容 + 顺序 + 唯一性**(不能只比行数——
    # 把 A/B 两行都改指 A 曾能通过)。逐条: 台账 hash == sha256(快照实际字节) == 清单行 hash;
    # snap 名唯一; 清单行序与台账序完全一致; 行数相等。
    if {![info exists ::env(FM_SIDECAR_OUT)] || $::env(FM_SIDECAR_OUT) eq ""} return
    set out $::env(FM_SIDECAR_OUT)
    if {![info exists ::SIDECAR_LEDGER]} { set ::SIDECAR_LEDGER {} }
    set in [open "$out/script_closure.list" r]; set lst [read $in]; close $in
    set rows {}
    foreach line [split $lst "\n"] {
        if {[string trim $line] eq ""} continue
        lappend rows [split $line "\t"]
    }
    if {[llength $rows] != [llength $::SIDECAR_LEDGER]} {
        sidecar_intercept_fail "closure_list_rowcount:[llength $rows]!=[llength $::SIDECAR_LEDGER]"
    }
    array set seen_snap {}
    for {set k 0} {$k < [llength $::SIDECAR_LEDGER]} {incr k} {
        lassign [lindex $::SIDECAR_LEDGER $k] l_orig l_snap l_hash
        lassign [lindex $rows $k] r_orig r_snap r_hash
        # 清单行与台账逐字段一致(顺序敏感)
        if {$l_orig ne $r_orig || $l_snap ne $r_snap || $l_hash ne $r_hash} {
            sidecar_intercept_fail "closure_row_mismatch:$k"
        }
        if {[info exists seen_snap($l_snap)]} { sidecar_intercept_fail "snapshot_dup:$l_snap" }
        set seen_snap($l_snap) 1
        if {![file exists "$out/$l_snap"]} { sidecar_intercept_fail "snapshot_missing:$l_snap" }
        set fh [open "$out/$l_snap" rb]; set got [read $fh]; close $fh
        set gh [sidecar_sha256_hex $got]
        # 快照实际字节 hash 必须 == 台账 hash(执行时刻记录) —— 篡改快照内容即露馅
        if {$gh ne $l_hash} { sidecar_intercept_fail "snapshot_tampered:$l_snap" }
    }
}
proc sidecar_install_appvar_guard {} {
    if {[info exists ::SIDECAR_GUARD_ON]} return
    set ::SIDECAR_GUARD_ON 1
    set ::SIDECAR_PHASE setup
    array set ::SIDECAR_AV_HISTORY {}
    trace add execution set_app_var enter sidecar_appvar_trace
    trace add execution source enter sidecar_source_trace
    if {[info commands match] ne ""} { trace add execution match enter sidecar_match_trace }
}

# ---------------- ② 有效值读回(verify 前)+ 写历史/快照台账一致性核对 ----------------
proc sidecar_capture_appvars {} {
    sidecar_verify_snapshot_ledger
    foreach k [concat $::SIDECAR_APPVAR_REQUIRED $::SIDECAR_EXTRA_KEYS] {
        set ::SIDECAR_AV($k) [get_app_var $k]
    }
    # 十审: entry_appvars 记**有效值**(get_app_var readback); FM 会规范化(如
    # blackbox_match_mode identity→Identity), 故不比对 set 参数字符串与 readback——
    # 安全性由 validator 三方绑定(native==envelope==expectation)+ 值域/冻结/放宽声明保证;
    # 篡改防护由执行 trace(每次 set 必记)+ phase 冻结 + rewrite-变值拒 承担。
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
# 严格 phase 文法状态机(3B 验收二审重写)。不再做"全局 marker 搜索+行白名单":
# 每行在**当前 phase** 内判合法性, marker 计数唯一, section 头限定 TECH|DESIGN 与
# ([ri]):/路径, FM-249 空报告不得夹带任何 section。
#   PRE          : 报告头(星线/字段/选项续行) → 唯一 FM-184 → MARKED
#   MARKED       : 可选唯一 FM-249(→EMPTY 终态); 图例框; banner; section 头 → SEC_HEAD
#   EMPTY        : 只允许尾部整数回显/空行(夹带 section/block → error)
#   SEC_HEAD     : 必须 Type 表头 → SEC_TABLE(缺表头 → error)
#   SEC_TABLE    : 必须 ---- 分隔 → BLOCKS(缺分隔 → error)
#   BLOCKS       : flag 块(Instances N==M>0, 精确 N 条路径, side==section, 禁重复);
#                  banner/新 section 头/尾部整数回显。section 内 0 block → error。
# 三审加锁: marker 锁**完整规范文本**(伪造 Information 行不再被认作 marker——
# 落到 unknown_information_line 拒); section 锁 TECH↔/FM_BBOX、DESIGN↔/WORK 配对;
# 整数回显进 TAIL 终态(其后任何内容拒); (side,path) **跨 i/u/e 类别全局拒重**。
set SIDECAR_FM184_TEXT "Information: Reporting black boxes for current reference and implementation designs. (FM-184)"
set SIDECAR_FM249_TEXT "Information: No 'black boxes' matched current 'reference and implementation designs'. (FM-249)"
# 四审: legend 有限文法——只接受以下**精确行**(自证据字节逐行提取)
set SIDECAR_LEGEND_LINES {
    { ___________________________________________________}
    {|                                                   |}
    {|  Legend:                                          |}
    {|           Black Box Attributes                    |}
    {|              s = Set with set_black_box command   |}
    {|              i = Module read with -interface_only |}
    {|              u = Unresolved design module         |}
    {|              e = Empty design module              |}
    {|              * = Unlinked design module           |}
    {|             ut = Unread tech cells pins           |}
    {|              L = Linked to non-black box design   |}
    {|             cp = Cutpoint blackbox                |}
    {|             ir = Internal rounded blackbox        |}
    {|              f = Formality Power Model            |}
    {|              m = Technology Macro cell (.db)      |}
    {|___________________________________________________|}
}
proc sidecar_parse_black_boxes {txt top} {
    array set acc {ir {} ii {} ur {} ui {} er {} ei {}}
    array set seen {}
    set fm184 0; set fm249 0
    set saw_report 0; set saw_ref 0; set saw_impl 0
    set ::SIDECAR_HDR_IDX 0; set ::SIDECAR_TAIL_SEEN 0
    set phase PRE
    set cur_side ""; set cur_kind ""; set sec_blocks 0; set total_blocks 0
    set lines [split $txt "\n"]
    set n [llength $lines]
    set i 0
    while {$i < $n} {
        set ln [string trimright [lindex $lines $i]]
        if {[string trim $ln] eq ""} { incr i; continue }
        # ---- marker(完整规范文本精确匹配; 计数唯一; 要求 header 三要素已核对) ----
        if {$ln eq $::SIDECAR_FM184_TEXT} {
            if {$fm184} { error "bbox_duplicate_FM184" }
            if {$phase ne "PRE"} { error "bbox_FM184_wrong_phase:$phase" }
            # 五审: FM-184 前 header 五字段必须全部按序出现(idx==5)
            if {$::SIDECAR_HDR_IDX != 5} { error "bbox_header_incomplete_before_FM184:idx$::SIDECAR_HDR_IDX" }
            set fm184 1; set phase MARKED; incr i; continue
        }
        if {$ln eq $::SIDECAR_FM249_TEXT} {
            if {$fm249} { error "bbox_duplicate_FM249" }
            if {$phase ne "MARKED"} { error "bbox_FM249_wrong_phase:$phase" }
            set fm249 1; set phase EMPTY; incr i; continue
        }
        if {[regexp {^Information:} $ln]} { error "bbox_unknown_information_line:$ln" }
        switch -- $phase {
            PRE {
                # 五审: 拒绝所有 option header(全量采集的 report_black_boxes 无 option 续行;
                # -interface_only 等过滤报告会带 " -option" 续行 → 拒, 防丢失 unresolved/empty)。
                if {[regexp {^\s+-\S} $ln]} { error "bbox_option_header_rejected:$ln" }
                # 五审: header 五字段各恰一次、顺序固定(Report/Reference/Implementation/Version/Date)
                if {[regexp {^\*+$} $ln]} { incr i; continue }
                if {[regexp {^([A-Za-z]+)\s+:\s+(.+)$} $ln -> key val]} {
                    set expect [lindex {Report Reference Implementation Version Date} $::SIDECAR_HDR_IDX]
                    if {$key ne $expect} { error "bbox_header_order:$key!=$expect" }
                    switch -- $key {
                        Report { if {$val ne "black_boxes"} { error "bbox_wrong_report_name:$val" }; set saw_report 1 }
                        Reference { if {$val ne "r:/WORK/$top"} { error "bbox_wrong_reference_top:$val" }; set saw_ref 1 }
                        Implementation { if {$val ne "i:/WORK/$top"} { error "bbox_wrong_implementation_top:$val" }; set saw_impl 1 }
                        Version { if {![regexp {^\S+$} $val]} { error "bbox_bad_version:$val" } }
                        Date { }
                    }
                    incr ::SIDECAR_HDR_IDX; incr i; continue
                }
                error "bbox_PRE_unparsed:$ln"
            }
            EMPTY {
                # 五审: TAIL 恰单行且严格 == "1"
                if {$ln eq "1"} { set phase TAIL; set ::SIDECAR_TAIL_SEEN 1; incr i; continue }
                error "bbox_empty_report_with_content:$ln"
            }
            TAIL {
                error "bbox_content_after_tail_echo:$ln"
            }
            MARKED - BLOCKS {
                if {$phase eq "MARKED" && \
                    ([string match { _*} $ln] || [string match {|*} $ln])} {
                    # 四审: legend 有限文法——非精确已知行拒
                    if {$ln ni $::SIDECAR_LEGEND_LINES} { error "bbox_unknown_legend_line:$ln" }
                    incr i; continue
                }
                if {[regexp {^#+$} $ln]} { incr i; continue }
                if {[regexp {^####\s+(TECH|DESIGN)\s+LIBRARY\s+-\s+([ri]):(/\S+)$} $ln -> kind s root]} {
                    if {!(($kind eq "TECH" && $root eq "/FM_BBOX") || \
                          ($kind eq "DESIGN" && $root eq "/WORK"))} {
                        error "bbox_section_kind_root_mismatch:$kind$root"
                    }
                    if {$phase eq "BLOCKS" && $sec_blocks == 0} { error "bbox_section_without_blocks" }
                    set cur_side $s; set cur_kind $kind; set sec_blocks 0; set phase SEC_HEAD; incr i; continue
                }
                if {[regexp {^####} $ln]} { error "bbox_bad_section_header:$ln" }
                if {$ln eq "1"} {
                    if {$phase eq "BLOCKS" && $sec_blocks == 0} { error "bbox_section_without_blocks" }
                    set phase TAIL; set ::SIDECAR_TAIL_SEEN 1; incr i; continue
                }
                if {$phase ne "BLOCKS"} { error "bbox_${phase}_unparsed:$ln" }
                # ---- BLOCKS: flag 块 ----
                if {![regexp {^(\S{1,2})\s+(\S+)$} $ln -> flag dname]} {
                    error "bbox_BLOCKS_unparsed:$ln"
                }
                if {$flag ni {i u e}} { error "bbox_unsupported_flag:${flag}:${dname}" }
                # 四审: flag 与 section 类别绑定——TECH(/FM_BBOX)只容 u(未解析);
                # DESIGN(/WORK)只容 i/e(interface_only/empty 是已读入设计库的模块)
                if {$cur_kind eq "TECH" && $flag ne "u"} {
                    error "bbox_flag_section_mismatch:${flag}_in_TECH"
                }
                if {$cur_kind eq "DESIGN" && $flag ni {i e}} {
                    error "bbox_flag_section_mismatch:${flag}_in_DESIGN"
                }
                set j [expr {$i+1}]
                while {$j < $n && [string trim [lindex $lines $j]] eq ""} { incr j }
                if {$j >= $n || ![regexp {^\s+Instances\s*:\s*(\d+)\s+of\s+(\d+)$} \
                                  [string trimright [lindex $lines $j]] -> N M]} {
                    error "bbox_${dname}_missing_instances_line"
                }
                if {$N != $M} { error "bbox_${dname}_instances_N_ne_M:${N}_of_${M}" }
                if {$N == 0} { error "bbox_${dname}_instances_zero_block" }
                set k [expr {$j+1}]
                set sep 0
                while {$k < $n && [regexp {^\s*-+\s*$} [lindex $lines $k]]} { set sep 1; incr k }
                if {!$sep} { error "bbox_${dname}_missing_separator" }
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
                    # 三审: (side,path) 全局唯一——同一路径跨 i/u/e 类别重复亦拒
                    if {[info exists seen($side,$pl)]} { error "bbox_${dname}_duplicate_path:$pl" }
                    set seen($side,$pl) 1
                    lappend acc($flag$side) $pl
                    incr got; incr k
                }
                if {$got != $N} { error "bbox_${dname}_path_count:${got}!=${N}" }
                if {$k < $n && [regexp {^\s+[ri]:/} [lindex $lines $k]]} {
                    error "bbox_${dname}_extra_path_beyond_N"
                }
                incr sec_blocks; incr total_blocks
                set i $k
                continue
            }
            SEC_HEAD {
                if {[regexp {^#+$} $ln]} { incr i; continue }   ;# banner 下沿
                if {[regexp {^Type\s+Design Name$} $ln]} { set phase SEC_TABLE; incr i; continue }
                error "bbox_section_missing_table_header:$ln"
            }
            SEC_TABLE {
                if {[regexp {^----\s+-+$} $ln]} { set phase BLOCKS; incr i; continue }
                error "bbox_section_missing_separator:$ln"
            }
        }
    }
    if {!$fm184} { error "bbox_report_missing_FM184" }
    # 五审: 成功终态必须恰为 TAIL 且恰见一行 "1"(0/-7/多整数均拒)
    if {$phase ne "TAIL"} { error "bbox_end_phase_not_TAIL:$phase" }
    if {$::SIDECAR_TAIL_SEEN != 1} { error "bbox_tail_not_single_one" }
    if {!$fm249 && $total_blocks == 0} { error "bbox_nonempty_claim_but_no_blocks" }
    return [list [lsort $acc(ir)] [lsort $acc(ii)] [lsort $acc(ur)] [lsort $acc(ui)] \
                 [lsort $acc(er)] [lsort $acc(ei)]]
}

# ---------------- pair 列表规整 ----------------
proc sidecar_pairs_sorted {raw} {
    # raw: fm -list 返回的 {{ref impl} ...}; 空侧("")拒(matched 语境不应出现)。
    # 排序须匹配 validator 的 Python sorted((ref,impl))=按 ref 再 impl 字典序。Tcl `lsort`
    # 对整对字符串排序在 impl 含花括号/多对时与 Python 元组序不一致(PtwCache 暴露)。
    # 用 "\n" 分隔键(路径无换行, \n=0x0A 小于任何路径字符)排序 → 与元组序等价。
    set keyed {}
    foreach p $raw {
        if {[llength $p] != 2} { error "pair_not_2elem:$p" }
        set r [lindex $p 0]; set i [lindex $p 1]
        if {$r eq "" || $i eq ""} { error "pair_empty_side:$p" }
        lappend keyed [list "$r\n$i" [list $r $i]]
    }
    set out {}
    foreach kp [lsort -index 0 $keyed] { lappend out [lindex $kp 1] }
    return $out
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
    # (script_closure.list 已由 sidecar_register_script 在每次 source 时**即时**落盘,
    #  连同执行时刻字节快照 sourced_NNN_*; 拒产会话同样留痕)

    # black_boxes(FM-184 状态机; report_black_boxes 自身 stdout 以单行 "1" 收尾=TAIL,
    # 五审实证: 3A 纯 stdout 捕获即以 "1" 结束, 不需 puts 包裹——那会产生两个 "1")
    redirect -variable bb_txt {report_black_boxes}
    lassign [sidecar_parse_black_boxes $bb_txt $top] if_r if_i un_r un_i em_r em_i

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
            # ci 规范化(FM 会改大小写: assume_reg_init/blackbox_match_mode)
            if {$k in {verification_assume_reg_init verification_blackbox_match_mode}} {
                set v [string tolower $v]
            }
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
