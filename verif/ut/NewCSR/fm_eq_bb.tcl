# NewCSR 集成层专用 FM 脚本（本 UT 目录私有，不改共享脚本）。
#
# 为什么需要专用脚本：
#   NewCSR 集成层例化 341 子模块，FM 两侧都把它们当黑盒。共享 fm_eq.tcl 的 impl 侧
#   不读 stub（impl 子模块会被自动建成「未知方向」黑盒），与 ref 侧显式方向 stub 的
#   黑盒边界对不齐。修法：ref/impl 两侧都读入同一份显式端口方向的 newcsr_stub.sv，
#   使黑盒边界逐引脚天然一致（默认 any 匹配即可，实测 0 unmatched，无需 identity 模式）。
#
# 经环境变量传参：FM_TOP / FM_REF_SRCS / FM_IMPL_SRCS / FM_MERGE_DUP /
#   FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS

set top       $env(FM_TOP)
set ref_srcs  $env(FM_REF_SRCS)
set impl_srcs $env(FM_IMPL_SRCS)

# --- sidecar 接线(305 统一判定; 本入口无独立 grep/WAIVED 判绿, 判定归 fm_sidecar_verdict.py)---
set SIDECAR_ON 0
if {[info exists env(FM_SIDECAR_OUT)] && [string trim $env(FM_SIDECAR_OUT)] ne ""} {
    set _xss $env(XSSV_HOME)
    source $_xss/scripts/sidecar/fm_native_emit.tcl
    set SIDECAR_ON 1
    set ::SIDECAR_SOURCED {}
    sidecar_register_script [file normalize [info script]]
    sidecar_register_script $_xss/scripts/sidecar/fm_native_emit.tcl
    sidecar_install_appvar_guard
}

set_app_var verification_verify_unread_compare_points false
# NewCSR target-scoped strengthening: diffArchEvent_{exception,interrupt}_r[62:32]
# 是 golden+impl bug-for-bug 对称死位(63 位寄存器只 [31:0] 喂 DelayReg, 高位无扇出)。
# false 时 FM 名字配对后不比较 → 62 matched-unread-notcompared → 判 PARTIAL。true 令 FM
# 实际比较这 62 点(两侧逻辑逐字相同 → 全等价 → +62 passing), 是证明加强(验证更多状态)
# 而非 waiver。值由 committed declaration/manifest 经 runner 绑入 provenance, 精确白名单守卫。
set _verify_matched_unread_compare_points "false"
if {[info exists env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)] &&
    [string trim $env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)] ne ""} {
    set _verify_matched_unread_compare_points \
        [string trim $env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)]
}
switch -- $_verify_matched_unread_compare_points {
  "true" {
    if {$top ne "NewCSR"} {
      puts "FM_MODE_ERROR: matched-unread strengthening 仅允许精确白名单, 当前 $top"
      exit 3
    }
  }
  "false" { }
  default {
    puts "FM_MODE_ERROR: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS 非法值 $_verify_matched_unread_compare_points"
    exit 3
  }
}
set_app_var verification_verify_matched_unread_compare_points \
    $_verify_matched_unread_compare_points
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set_app_var hdlin_unresolved_modules black_box

set _merge_dup false
if {[info exists env(FM_MERGE_DUP)]} { set _merge_dup $env(FM_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $_merge_dup

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# NewCSR 例化 341 子模块; ref/impl 两侧都读入同一份显式端口方向的 newcsr_stub.sv,
# 黑盒名字+签名逐引脚天然一致(实测 0 unmatched, 无需 identity 模式或逐点钉死)。
# 不设 verification_blackbox_match_mode(默认 any) → 不产生 relaxed_appvars 资格。

match

report_unmatched_points > fm_work/$top/unmatched.rpt
report_matched_points   > fm_work/$top/matched.rpt

if {$SIDECAR_ON} { sidecar_capture_appvars }
if {[verify]} {
    puts "FM_RESULT: Verification SUCCEEDED for $top"
} else {
    redirect fm_work/$top/failing.rpt { report_failing_points }
    puts "FM_RESULT: Verification FAILED or INCONCLUSIVE for $top"
}
if {$SIDECAR_ON} { sidecar_emit $top }
exit
