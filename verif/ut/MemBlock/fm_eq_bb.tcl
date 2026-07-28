# MemBlock assembly FM 脚本（codex_0074 owner#6，本 UT 目录私有，不改任何共享脚本）。
#
# 装配边界（assembly proof_mode）：
#   MemBlock 是访存子系统顶层互联，例化 49 类共 71 个子模块。分三层处理——
#     (A) 黑盒 34 类（memblock_bb_stub.sv，两侧共读）：20 green-305 SIGNOFF_PASS +
#         14 aux-PASS child。这些 child 各自独立签核已 PASS，依赖闭合；在本层作为
#         对称显式端口方向黑盒（identity 配对），FM 只验本层到它们端口的互联 glue。
#     (B) 两侧 elaborate 26 glue golden（GLUE_GOLDEN，两侧共读真实 RTL 非黑盒）：
#         HPerfMonitor_3/HPerfCounter_21、PFEvent/perfEventsModule、FrontendBridge/
#         ICache*Buffer/InstrUncacheBuffer/Queue2×6、Mbist{Intf,PipeMemBlk,PipeSms}、
#         DelayN_{332,8}、DelayNWithValid_{2,200,202,203,3}、PipelineRegModule{,_6}。
#         这些是本层真实功能（perf 事件汇聚 → io_perf_*、MBIST 分发、打拍/延迟线）。
#         **glue 必须两侧真实 elaborate**：HPerfMonitor_3 驱动 io_perf_0..7_value 的 2 级
#         流水，若黑盒则 FM 对同构 perf cone 做黑盒符号推理会产生假失配（历史 FAILED 根因）。
#     (C) 厂商 SRAM 宏：本 glue 层无 SRAM；黑盒 34 类内部的 SRAM 随其黑盒消隐。
#
#   两侧同一份 stub + 同一份 glue golden ⇒ 装配边界逐引脚对齐，比对聚焦本层 glue。
#
# 经环境变量传参：FM_TOP / FM_REF_SRCS / FM_IMPL_SRCS / FM_MERGE_DUP /
#                  FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS(runner 控)

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
# vmucp: 对称 matched-unread 死寄存器（glue 内 golden 宽存窄读 / assert-only cone-dead，
# 两侧同名同驱动双射）由 runner 经 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS 控制。
# =true 时 FM 实际逐位比较 matched-unread 双射点（真等价证明），缺省 false。
set _vmucp false
if {[info exists env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)]} {
    set _vmucp $env(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS)
}
set_app_var verification_verify_matched_unread_compare_points $_vmucp
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

# 黑盒引脚按「名字+位置」配对（identity）：34 类黑盒的边界命名结构一致可自动配对，
# 避免对同构 perf 引脚的功能配对歧义。
set_app_var verification_blackbox_match_mode identity

# ---------------------------------------------------------------------------
# perf 2 级流水钉点：golden 把 8 路 perf 展平成 inner_io_perf_<n>_value_REG/_REG_1，
# 可读核用 perf_cnt_t 数组 perf_stage1_reg[n][b]/perf_stage2_reg[n][b]。名字结构不同，
# 历史上 FM 拓扑配对会把 [1]/[2] 错位（旧 FAILED 20 点全落 perf_stage*_reg[1]/io_perf_1/2）。
# 逐路 set_user_match 钉死（同 DCache/DCacheWrapper/LsqWrapper 的 perf 处理）。
# ---------------------------------------------------------------------------
if {[file exists [file join [file dirname [info script]] fm_pins.tcl]]} {
    source [file join [file dirname [info script]] fm_pins.tcl]
}

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
