# 执行期 appvar 拦截对抗测试(acceptance gate 2, tclsh; 验收二审语义)。
# 二审裁定: 一审 rename+wrapper 暴露原生别名 __sidecar_real_set_app_var 可绕过。
# 现为 execution trace 加在命令本身(无旁路别名)+ phase(match 后冻结)+ 写历史
# (变值重写拒/readback 核对)。
set here [file dirname [file normalize [info script]]]
set ::env(FM_SIDECAR_OUT) [file join $here .ti_snapdir]
file delete -force $::env(FM_SIDECAR_OUT)
file mkdir $::env(FM_SIDECAR_OUT)

# 桩: 模拟 fm 原生命令
set ::APPLIED {}
array set ::AVMAP {}
proc set_app_var {name value} {
    lappend ::APPLIED [list $name $value]; set ::AVMAP($name) $value; return $value }
proc get_app_var {name} { if {[info exists ::AVMAP($name)]} { return $::AVMAP($name) }; return "" }
proc set_user_match {args} { lappend ::USERMATCH $args }
proc match {} { return 1 }
# 桩: 只读查询命令(redirect -variable 捕获其输出; CtrlBlock 现场推导 unmatched 用)
proc report_unmatched_points {args} {
    return "  Ref DFF  r:/WORK/T/foo_reg\n  Impl DFF  i:/WORK/T/u_core/bar_reg" }

source $here/fm_native_emit.tcl
set ::INTERCEPTED {}
proc sidecar_intercept_fail {reason} { lappend ::INTERCEPTED $reason; error "intercepted:$reason" }
sidecar_install_appvar_guard

set pass 0; set fail 0
proc T {name script} {
    global pass fail
    if {[catch {uplevel 1 $script} msg]} { puts "FAIL  $name: $msg"; incr fail } \
    else { puts "PASS  $name"; incr pass }
}

# ---- 二审旁路复现: 不再存在暴露的原生别名 ----
T no_exposed_native_alias {
    if {[info commands __sidecar_real_set_app_var] ne ""} { error "旁路别名仍存在" }
}
T legal_direct_passthrough {
    set_app_var hdlin_unresolved_modules black_box
    if {[lindex $::APPLIED end] ne {hdlin_unresolved_modules black_box}} { error "未透传" }
}
T legal_optional_recorded_and_history {
    set_app_var verification_propagate_const_reg_x true
    if {"verification_propagate_const_reg_x" ni $::SIDECAR_EXTRA_KEYS} { error "可选键未记账" }
    if {$::SIDECAR_AV_HISTORY(verification_propagate_const_reg_x) ne "true"} { error "历史缺失" }
}
T idempotent_rewrite_same_value_ok {
    set_app_var verification_propagate_const_reg_x true
}
T rewrite_changed_value_rejected {
    if {![catch {set_app_var verification_propagate_const_reg_x false}]} { error "变值重写未拦截" }
    if {![string match "*rewrite_changed_value*" [lindex $::INTERCEPTED end]]} { error "类别不符" }
    if {$::AVMAP(verification_propagate_const_reg_x) ne "true"} { error "变值竟已生效" }
}
T illegal_direct {
    if {![catch {set_app_var verification_timeout_limit 100}]} { error "未拦截" }
    if {![string match "*not-in-registry*" [lindex $::INTERCEPTED end]]} { error "类别不符" }
    if {[info exists ::AVMAP(verification_timeout_limit)]} { error "非法值竟已生效" }
}
T illegal_dynamic_command_name {
    set c set_app_var
    if {![catch {$c verification_clock_gate_hold_mode any}]} { error "动态名未拦截" }
}
T illegal_via_eval {
    if {![catch {eval [list set_app_var verification_effort_level high]}]} { error "eval未拦截" }
}
T illegal_via_nested_source {
    set inner [file join $::here .ti_inner.tcl]
    set outer [file join $::here .ti_outer.tcl]
    set fh [open $inner w]; puts $fh {set_app_var hdlin_ignore_parallel_case true}; close $fh
    set fh [open $outer w]; puts $fh "source $inner"; close $fh
    set rc [catch {source $outer}]
    file delete $inner $outer
    if {!$rc} { error "嵌套source未拦截" }
}
T source_encoding_form_records_file_not_flag {
    # 三审复现: source -encoding utf-8 real.tcl 曾把 "-encoding" 记成路径
    set f [file join $::here .ti_enc.tcl]
    set fh [open $f w]; puts $fh {set __enc_ok 1}; close $fh
    set ::SIDECAR_SOURCED {}
    source -encoding utf-8 $f
    file delete $f
    if {[llength $::SIDECAR_SOURCED] != 1} { error "应记1条, 得 $::SIDECAR_SOURCED" }
    if {[file tail [lindex $::SIDECAR_SOURCED 0]] ne ".ti_enc.tcl"} { error "记错: $::SIDECAR_SOURCED" }
}
T snapshot_bytes_at_execution {
    # 快照字节 == 执行时字节(TOCTOU 消除的可测部分)
    set f [file join $::here .ti_snap.tcl]
    set fh [open $f w]; puts -nonewline $fh {set __snap_ok 1}; close $fh
    source $f
    set snaps [glob -nocomplain $::env(FM_SIDECAR_OUT)/sourced_*_.ti_snap.tcl]
    file delete $f
    if {[llength $snaps] != 1} { error "快照缺失" }
    set fh [open [lindex $snaps 0] r]; set b [read $fh]; close $fh
    if {$b ne {set __snap_ok 1}} { error "快照字节不符" }
}
T source_trace_records_nested {
    set inner [file join $::here .ti_src_inner.tcl]
    set outer [file join $::here .ti_src_outer.tcl]
    set fh [open $inner w]; puts $fh {set __benign 1}; close $fh
    set fh [open $outer w]; puts $fh "source $inner"; close $fh
    set ::SIDECAR_SOURCED {}
    source $outer
    file delete $inner $outer
    # 递归记账: outer 与 inner 都必须入 closure 清单
    if {[llength $::SIDECAR_SOURCED] != 2} { error "记账应2条, 得 $::SIDECAR_SOURCED" }
}
T comment_and_string_no_false_positive {
    set n [llength $::INTERCEPTED]
    # set_app_var verification_fake_in_comment 1
    set s "set_app_var verification_fake_in_string 1"
    if {[llength $::INTERCEPTED] != $n} { error "文本被误报" }
}
# ---- 四审: pin 进受限 child interp ----
T pin_child_source_snapshot_and_exec {
    set f [file join $::here .ti_pin1.tcl]
    set fh [open $f w]; puts $fh {set_user_match r:/WORK/T/a i:/WORK/T/b}; close $fh
    set ::USERMATCH {}
    sidecar_pin_source $f
    file delete $f
    if {[llength $::USERMATCH] != 1} { error "set_user_match 未透传" }
    set snaps [glob -nocomplain $::env(FM_SIDECAR_OUT)/sourced_*_.ti_pin1.tcl]
    if {[llength $snaps] != 1} { error "pin 快照缺失" }
}
T pin_child_cannot_touch_parent_guard {
    # 四审复现: 同解释器可 set ::SIDECAR_PHASE / trace remove 拆除 guard——child 里两者
    # 只作用于 child 自身, 父层 guard 不受影响: 随后非法 set_app_var 仍被拦
    set f [file join $::here .ti_pin2.tcl]
    set fh [open $f w]
    puts $fh {set ::SIDECAR_PHASE setup}
    puts $fh {catch {trace remove execution set_app_var enter sidecar_appvar_trace}}
    puts $fh {set_app_var verification_timeout_limit 100}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "guard 被拆除" }
    if {![string match "*not-in-registry*" [lindex $::INTERCEPTED end]]} { error "类别不符: $msg" }
    if {[info exists ::AVMAP(verification_timeout_limit)]} { error "非法值生效" }
}
T pin_child_no_file_io {
    # safe interp 无 open/file/exec → pin 不能写证据目录/覆盖快照
    set f [file join $::here .ti_pin3.tcl]
    set fh [open $f w]; puts $fh {open /tmp/evil w}; close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "child 竟有 file I/O" }
}
T pin_child_nested_source_controlled {
    # child 内 source 走受控入口: 快照+同缓冲执行
    set inner [file join $::here .ti_pin_inner.tcl]
    set outer [file join $::here .ti_pin_outer.tcl]
    set fh [open $inner w]; puts $fh {set_user_match r:/WORK/T/x i:/WORK/T/y}; close $fh
    set fh [open $outer w]; puts $fh "source $inner"; close $fh
    set ::USERMATCH {}
    sidecar_pin_source $outer
    file delete $inner $outer
    if {[llength $::USERMATCH] != 1} { error "嵌套未执行" }
    if {[llength [glob -nocomplain $::env(FM_SIDECAR_OUT)/sourced_*_.ti_pin_inner.tcl]] != 1} { error "嵌套快照缺失" }
}
T snapshot_ledger_tamper_detected {
    # 执行后篡改快照文件 → capture 前复核拒(hash 不符)
    set snaps [glob $::env(FM_SIDECAR_OUT)/sourced_*_.ti_pin1.tcl]
    set fh [open [lindex $snaps 0] a]; puts $fh "tamper"; close $fh
    set rc [catch {sidecar_verify_snapshot_ledger}]
    if {!$rc} { error "篡改未检出" }
    if {![string match "*snapshot_tampered*" [lindex $::INTERCEPTED end]]} { error "类别不符" }
    # 复原快照(后续测试用)
    set orig [lindex $::SIDECAR_LEDGER 0]
    # 重写为原始状态: 用台账 hash 对应内容不可逆, 直接删重建场景交给独立台账不改
}
T closure_list_AB_to_AA_tamper_detected {
    # 五审复现: 把执行过的 A/B 两行都改指 A(数量不变) → 只比行数曾能过; 现逐字段核对拒
    set out $::env(FM_SIDECAR_OUT)
    # 造两条干净台账 + 清单
    set ::SIDECAR_LEDGER {}; set ::SIDECAR_SRC_SEQ 0
    file delete -force $out; file mkdir $out
    sidecar_snapshot_buffer /x/A.tcl "content-A"
    sidecar_snapshot_buffer /x/B.tcl "content-B"
    # 篡改清单: 把第二行(B)改成指向 A 的快照(行数仍=2)
    set _fh [open $out/script_closure.list r]; set _c [read $_fh]; close $_fh
    set rows [split [string trimright $_c] "\n"]
    lassign [split [lindex $rows 0] "\t"] a_orig a_snap a_hash
    set fh [open $out/script_closure.list w]
    puts $fh [lindex $rows 0]
    puts $fh "$a_orig\t$a_snap\t$a_hash"
    close $fh
    set rc [catch {sidecar_verify_snapshot_ledger}]
    if {!$rc} { error "AA 篡改未检出" }
    if {![string match "*closure_row_mismatch*" [lindex $::INTERCEPTED end]]} { error "类别不符: [lindex $::INTERCEPTED end]" }
}
T history_mismatch_detected_at_readback {
    # 纵深防御: readback 与写历史**不同值**(非仅大小写)→ capture 拒。
    # 复位快照台账(前序测试留下的脏 closure 不影响本 appvar 检查)
    set ::SIDECAR_LEDGER {}
    set _o $::env(FM_SIDECAR_OUT); file delete -force $_o; file mkdir $_o
    set _fh [open $_o/script_closure.list w]; close $_fh

    # (大小写不敏感: 若仅大小写差异如 identity/Identity 不应误报——见 ci_normalization 用例)
    set ::AVMAP(verification_propagate_const_reg_x) false   ;# 绕过桩直接篡改为不同值
    if {![catch {sidecar_capture_appvars}]} { error "history mismatch 未拦截" }
    if {![string match "*history_mismatch*" [lindex $::INTERCEPTED end]]} { error "类别不符" }
    set ::AVMAP(verification_propagate_const_reg_x) true
}
T history_ci_normalization_not_false_positive {
    # FM 规范化(identity→Identity)大小写差异不得误报为篡改
    # 复位快照台账(前序测试留下的脏 closure 不影响本 appvar 检查)
    set ::SIDECAR_LEDGER {}
    set _o $::env(FM_SIDECAR_OUT); file delete -force $_o; file mkdir $_o
    set _fh [open $_o/script_closure.list w]; close $_fh

    set ::SIDECAR_AV_HISTORY(verification_blackbox_match_mode) identity
    set ::AVMAP(verification_blackbox_match_mode) Identity
    if {[catch {sidecar_capture_appvars} m]} { error "大小写差异误报: $m" }
    unset ::SIDECAR_AV_HISTORY(verification_blackbox_match_mode)
    catch {unset ::AVMAP(verification_blackbox_match_mode)}
}
# ---- phase: 首次 match 后 **frozen-semantics 必须键** 冻结("先放宽-match-恢复"堵死) ----
T phase_frozen_required_after_match {
    match
    # REQUIRED(frozen-semantics)appvar post-match → 拒(防藏 unread)
    if {![catch {set_app_var verification_verify_unread_compare_points true}]} { error "match后REQUIRED未拦截" }
    if {![string match "*phase_violation*" [lindex $::INTERCEPTED end]]} { error "类别不符" }
}
T phase_optional_relaxing_allowed_after_match {
    # OPTIONAL relaxing appvar post-match 允许(post-match pin 合法; 记relaxed→PARTIAL不藏SUCCEEDED)
    set n [llength $::INTERCEPTED]
    set_app_var verification_assume_reg_init Conservative
    if {[llength $::INTERCEPTED] != $n} { error "OPTIONAL post-match 被误拦" }
    if {"verification_assume_reg_init" ni $::SIDECAR_EXTRA_KEYS} { error "OPTIONAL未记账(应入relaxed)" }
}
# ---- sidecar-pin-compat: 只读 redirect 兼容(codex_0088 §5) ----
# 正测: CtrlBlock 实际用法 `redirect -variable um_txt {report_unmatched_points}` 现通过,
# 被捕获文本回写 child 变量, 后续 set_user_match 生效(过去 invalid command name → rc=1)。
T redirect_variable_capture_readonly_ok {
    set f [file join $::here .ti_pin_redir.tcl]
    set fh [open $f w]
    puts $fh {redirect -variable um_txt {report_unmatched_points}}
    puts $fh {if {![string match "*foo_reg*" $um_txt]} { error "capture failed" }}
    puts $fh {set_user_match r:/WORK/T/foo_reg i:/WORK/T/u_core/bar_reg}
    close $fh
    set ::USERMATCH {}
    sidecar_pin_source $f
    file delete $f
    if {[llength $::USERMATCH] != 1} { error "redirect 捕获后 set_user_match 未生效" }
}
# 负测: 裸文件写到任意路径被拒(修改类能力不放行, fail-closed)
T redirect_bare_file_arbitrary_path_rejected {
    set f [file join $::here .ti_pin_redir2.tcl]
    set fh [open $f w]
    puts $fh {redirect /tmp/evil_pin_out.txt {report_unmatched_points}}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "裸文件写未拦截" }
    if {[file exists /tmp/evil_pin_out.txt]} { file delete /tmp/evil_pin_out.txt; error "任意路径文件竟被写" }
}
# 负测: -append 到证据目录外/无前缀文件被拒
T redirect_file_missing_prefix_rejected {
    set f [file join $::here .ti_pin_redir3.tcl]
    set fh [open $f w]
    puts $fh {redirect um_report.txt {report_unmatched_points}}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "无 pin_redirect_ 前缀文件写未拦截" }
}
# 负测: 路径穿越(..)被拒, 即便有 pin_redirect_ 前缀
T redirect_file_path_traversal_rejected {
    set f [file join $::here .ti_pin_redir4.tcl]
    set fh [open $f w]
    puts $fh {redirect pin_redirect_../escape.txt {report_unmatched_points}}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "路径穿越未拦截" }
}
# 负测: 未知 flag(如 -channel/-tee)被拒(不静默降级为文件写)
T redirect_unknown_flag_rejected {
    set f [file join $::here .ti_pin_redir5.tcl]
    set fh [open $f w]
    puts $fh {redirect -channel somechan {report_unmatched_points}}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "未知 flag 未拦截" }
}
# 正测: 只读报告导到证据目录内 pin_redirect_ 文件(任务允许的 file 只读报告用法)
T redirect_file_evidence_dir_allowed {
    set f [file join $::here .ti_pin_redir6.tcl]
    set fh [open $f w]
    puts $fh {redirect pin_redirect_um.rpt {report_unmatched_points}}
    close $fh
    sidecar_pin_source $f
    file delete $f
    set rpt [file join $::env(FM_SIDECAR_OUT) pin_redirect_um.rpt]
    if {![file exists $rpt]} { error "证据目录内只读报告未写出" }
    set fh [open $rpt r]; set c [read $fh]; close $fh
    if {![string match "*foo_reg*" $c]} { error "报告内容不符" }
    file delete $rpt
}
# 负测(核心): redirect 不能被当作**修改类命令**载体绕过父层拦截。被包裹的 <script>
# 仍在 child safe interp 内执行 → 非法 set_app_var 照常触发父层 execution trace(生产里
# sidecar_intercept_fail=exit 3, child catch 拦不住进程退出), 且**非法值绝不生效**。
# 未被 pin catch 时错误照常上抛(rc=1)。
T redirect_body_unknown_appvar_guard_fires_and_no_effect {
    set n [llength $::INTERCEPTED]
    set f [file join $::here .ti_pin_redir7.tcl]
    set fh [open $f w]
    puts $fh {redirect -variable z {set_app_var verification_timeout_limit 100}}
    close $fh
    set rc [catch {sidecar_pin_source $f} msg]
    file delete $f
    if {!$rc} { error "redirect 包裹的非法 set_app_var 未上抛" }
    if {[llength $::INTERCEPTED] <= $n} { error "父层 guard 未触发" }
    if {![string match "*not-in-registry*" [lindex $::INTERCEPTED end]]} { error "类别不符: [lindex $::INTERCEPTED end]" }
    if {[info exists ::AVMAP(verification_timeout_limit)]} { error "非法值经 redirect 竟生效" }
}
# 负测: 即便 pin 用 catch 吞掉 guard 的 error(生产是 exit 3 吞不掉), 非法值仍绝不生效。
T redirect_body_caught_error_still_no_effect {
    set n [llength $::INTERCEPTED]
    set f [file join $::here .ti_pin_redir7b.tcl]
    set fh [open $f w]
    puts $fh {catch {redirect -variable z {set_app_var verification_effort_level high}}}
    close $fh
    catch {sidecar_pin_source $f}
    file delete $f
    if {[llength $::INTERCEPTED] <= $n} { error "父层 guard 未触发" }
    if {[info exists ::AVMAP(verification_effort_level)]} { error "非法值经 catch+redirect 竟生效" }
}

puts "$pass/[expr {$pass+$fail}] passed"
if {$fail} { exit 1 }
