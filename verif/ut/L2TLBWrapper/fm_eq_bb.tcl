# L2TLBWrapper 专用 FM 脚本（本 UT 目录私有，不改任何共享脚本）。
#
# 为什么需要专用脚本（本地黑盒注入，非放宽证明）：
#   L2TLBWrapper 把内层 L2TLB 黑盒的 19 路 perf 输出 io_perf_<i>_value 各打 2 级寄存器。
#   共享 fm-% 规则的 ref 侧固定只取 $(GOLDEN_RTL)/$*.sv，无法在 ref/impl 两侧同时注入
#   带【显式端口方向】的 L2TLB 黑盒声明（l2tlb_blackbox.sv）。若不注入，firtool 生成的
#   黑盒会是「unknown direction」，两侧对内层 L2TLB 巨型黑盒的端口拓扑推断可能不一致。
#   故本脚本直接从 Makefile fmbb 目标接收两侧 srcs（各自带上同一份 l2tlb_blackbox.sv），
#   在 ref/impl 两侧读入【完全相同】的黑盒边界。除此之外，本脚本与共享 fm_eq.tcl 的
#   appvar 政策逐字一致（六元 unread 政策 + hdlin_unresolved_modules=black_box），
#   【不放宽任何 proof-affecting appvar】：黑盒引脚按 FM 默认 match 模式配对。
#
#   历史注记：早期版本曾用 verification_blackbox_match_mode identity「消歧」+ 失败点
#   grep-WAIVED 兜底。经 FM 审计（2026-07）证实二者均非必要且违背签核铁律：
#     (a) 两侧注入显式端口的 l2tlb_blackbox.sv 后，19 路同名 perf 引脚在【默认】match
#         模式下即按名字精确配对（1141 by name + 1486 by signature），无需 identity
#         （非默认 blackbox_match_mode = 放宽证明，会进 qualifications.relaxed_appvars →
#          assembly 判 PARTIAL，是硬墙）；
#     (b) grep-WAIVED 是「本入口独立判绿」，与 305 统一判定（fm_sidecar_verdict.py）
#         冲突且被禁。判定一律归 sidecar；native SUCCEEDED + empty_bb 政策匹配才算绿。
#   实测：去掉 identity 与 WAIVED 后，native = SUCCEEDED（2627 passing / 0 failing /
#         0 unmatched / 0 unread），relaxed_appvars 为空。
#
# 内层 L2TLB = 305 绿 target（SIGNOFF_PASS），本层 assembly 闭包将其作 empty_blackbox
#   端口桩（allow: verif/signoff/allow/L2TLBWrapper.json 的 empty_blackbox=ptw；
#   assembly_depends: L2TLBWrapper -> L2TLB）。
#
# 经环境变量传参：FM_TOP / FM_REF_SRCS / FM_IMPL_SRCS / FM_MERGE_DUP

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
set_app_var verification_verify_matched_unread_compare_points false
set_app_var verification_verify_unread_bbox_inputs false
set_app_var verification_verify_matched_unread_bbox_inputs true
set_app_var verification_verify_unread_tech_cell_pins true
set_app_var verification_verify_unread_tech_cell_pg_pins true
set_app_var hdlin_unresolved_modules black_box

set _merge_dup true
if {[info exists env(FM_MERGE_DUP)]} { set _merge_dup $env(FM_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $_merge_dup

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

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
