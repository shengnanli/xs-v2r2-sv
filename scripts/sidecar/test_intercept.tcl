# 执行期 appvar 拦截对抗测试(acceptance gate 2, tclsh)。
# 验收一审裁定: 静态正则扫描不合格(动态命令名/eval/嵌套 source 绕过)。本测试证明
# rename+wrapper 在**真实执行点**拦截, 上述三种绕过路径全部落网; 合法调用透传并记账。
set here [file dirname [file normalize [info script]]]

# 桩: 模拟原生 set_app_var(fm 环境外)
set ::APPLIED {}
proc set_app_var {name value} { lappend ::APPLIED [list $name $value]; return $value }

source $here/fm_native_emit.tcl

# fail 钩子替换为记录+error(不 exit, 使测试可断言)
set ::INTERCEPTED {}
proc sidecar_intercept_fail {name} { lappend ::INTERCEPTED $name; error "intercepted:$name" }

sidecar_install_appvar_guard

set pass 0; set fail 0
proc T {name script} {
    global pass fail
    if {[catch {uplevel 1 $script} msg]} { puts "FAIL  $name: $msg"; incr fail } \
    else { puts "PASS  $name"; incr pass }
}

T legal_direct_passthrough {
    set_app_var hdlin_unresolved_modules black_box
    if {[lindex $::APPLIED end] ne {hdlin_unresolved_modules black_box}} { error "未透传" }
}
T legal_optional_recorded {
    set_app_var verification_propagate_const_reg_x true
    if {"verification_propagate_const_reg_x" ni $::SIDECAR_EXTRA_KEYS} { error "可选键未记账" }
}
T illegal_direct {
    if {![catch {set_app_var verification_timeout_limit 100} msg]} { error "未拦截" }
    if {[lindex $::INTERCEPTED end] ne "verification_timeout_limit"} { error "记录缺失" }
}
T illegal_dynamic_command_name {
    # 静态扫描的盲区1: 动态命令名
    set c set_app_var
    if {![catch {$c verification_clock_gate_hold_mode any} msg]} { error "动态名未拦截" }
    if {[lindex $::INTERCEPTED end] ne "verification_clock_gate_hold_mode"} { error "记录缺失" }
}
T illegal_via_eval {
    # 盲区2: eval 组装
    if {![catch {eval [list set_app_var verification_effort_level high]}]} { error "eval未拦截" }
    if {[lindex $::INTERCEPTED end] ne "verification_effort_level"} { error "记录缺失" }
}
T illegal_via_nested_source {
    # 盲区3: 嵌套 source(pin 文件 source 另一文件)
    set inner [file join $::here .test_intercept_inner.tcl]
    set outer [file join $::here .test_intercept_outer.tcl]
    set fh [open $inner w]; puts $fh {set_app_var hdlin_ignore_parallel_case true}; close $fh
    set fh [open $outer w]; puts $fh "source $inner"; close $fh
    set rc [catch {source $outer} msg]
    file delete $inner $outer
    if {!$rc} { error "嵌套source未拦截" }
    if {[lindex $::INTERCEPTED end] ne "hdlin_ignore_parallel_case"} { error "记录缺失" }
}
T comment_and_string_no_false_positive {
    # 静态扫描的误报源: 注释/字符串中的 set_app_var 文本——执行期 wrapper 天然免疫
    set n_before [llength $::INTERCEPTED]
    # set_app_var verification_fake_in_comment 1
    set s "set_app_var verification_fake_in_string 1"
    if {[llength $::INTERCEPTED] != $n_before} { error "文本被误报" }
}
puts "$pass/[expr {$pass+$fail}] passed"
if {$fail} { exit 1 }
