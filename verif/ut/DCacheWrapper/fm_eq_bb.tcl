# DCacheWrapper 专用 FM 脚本（本 UT 目录私有，不改任何共享脚本）。
#
# 为什么需要专用脚本：
#   DCacheWrapper 唯一自有逻辑是把内层 DCache 黑盒的 32 路 perf 输出各打 2 级寄存器；
#   ref/impl 两侧都读入同名同向的空 DCache 黑盒（dcache_blackbox.sv），黑盒引脚同名
#   同向 → 默认 any 匹配即逐引脚天然一致（实测 0 unmatched，无需 identity 模式）。
#   其余流程与共享 fm_eq.tcl 等价，判定完全交给 native verify()/sidecar，无任何
#   grep/WAIVED 判绿，也不设 verification_blackbox_match_mode（默认 any，不产生
#   relaxed_appvars 资格 → assembly 可判 clean SUCCEEDED，参 NewCSR 先例）。
#   注: perf 输出早前的 io_perf_0/10 功能配对歧义根因是 impl perf 寄存器误加同步复位
#   （reset 在 impl cone 不在 ref cone），已在 rtl/memblock/DCacheWrapper.sv 修正对齐
#   golden 无复位；修正后两侧 cone 对称，any 模式即无歧义，故 identity 不再需要。
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

# 不设 verification_blackbox_match_mode（默认 any）：两侧 DCache 黑盒同名同向，perf
# 输出引脚 any 匹配即逐引脚天然一致（实测 0 unmatched）。设 identity 会作为放宽资格
# 进 relaxed_appvars 令 assembly 判 PARTIAL（sidecar quals_any）；修完 perf 复位对齐
# golden 后 identity 已不再需要（参 NewCSR 先例）。

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
