# NewCSR 父层装配 FM 脚本（本 UT 目录私有，不改共享脚本）。
#
# 与旧 fm_eq_bb.tcl 的区别（诚实的父层证明，非黑盒占位）：
#   旧脚本把 341 个 CSR 字段子模块全部当黑盒（两侧同读 newcsr_stub.sv），只证顶层接线，
#   字段逻辑零验证（reviewer NO-GO 的空洞）。本脚本让全部 296 个真实字段模块两侧
#   elaborate（golden 字段 .sv vs 可读 impl 核），逐位比较字段逻辑；仅 13 个纯外部
#   DPI difftest 包装（DummyDPICWrapper_12..23 + CommitIDModule，无可综合 golden 体，
#   仅例化 DiffExt*/PrintCommitID DPI-C sink）保持 unresolved 黑盒（两侧同名同签名
#   自动配对，声明于 verif/signoff/allow/NewCSR.json 的 unresolved_blackbox）。
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
# NewCSR target-scoped strengthening（vmucp）: 顶层 diffArchEvent_{exception,interrupt}_r
# 的 62 个高位（63 位寄存器只 [31:0] 喂 DelayReg，高位无扇出）+ HPerfMonitor_1 内 40 个
# 对称死 DFF，都是 golden+impl bug-for-bug 对称死位。false 时 FM 名字配对后不比较 →
# 计 matched-unread-notcompared → 判 PARTIAL。true 令 FM 实际比较这些点（两侧逻辑逐字
# 相同 → 全等价 → 计 passing），是证明加强（验证更多状态）而非 waiver。值由 committed
# declaration/manifest 经 runner 绑入 provenance，精确白名单守卫（仅 NewCSR）。
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
# 13 个 DPI 包装无 RTL 体 → 自动黑盒（unresolved）；两侧同名同签名。
set_app_var hdlin_unresolved_modules black_box

set _merge_dup false
if {[info exists env(FM_MERGE_DUP)]} { set _merge_dup $env(FM_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $_merge_dup

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# 默认 blackbox_match_mode=any：13 个 DPI 黑盒两侧同名自动配对（不设 identity，
# 不产生 relaxed_appvars 资格 → 不因 blackbox_match_mode 判 PARTIAL）。
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
