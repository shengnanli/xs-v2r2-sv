# DCache 集成层专用 FM 脚本（本 UT 目录私有，不改共享脚本）。
#
# 为什么需要专用脚本：
#   DCache 集成层例化 30+ 子模块，FM 两侧都把它们当黑盒。共享 fm_eq.tcl 的 impl 侧
#   不读 stub（impl 子模块会被自动建成「未知方向」黑盒，26545 个 unknown-direction
#   pin），与 ref 侧显式方向 stub 的黑盒边界对不齐，match 大面积失败。
#   修法：ref/impl 两侧都读入显式端口方向的 dcache_stub.sv，并用 identity 黑盒配对，
#   使黑盒边界逐引脚对齐。
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

set _merge_dup false
if {[info exists env(FM_MERGE_DUP)]} { set _merge_dup $env(FM_MERGE_DUP) }
set_app_var verification_merge_duplicated_registers $_merge_dup

read_sverilog -r -define {SYNTHESIS} $ref_srcs
set_top r:/WORK/$top

read_sverilog -i -define {SYNTHESIS} $impl_srcs
set_top i:/WORK/$top

# 黑盒引脚按「名字+位置」对齐（30+ 同构子模块，function 配对会有歧义）。
set_app_var verification_blackbox_match_mode identity

# --------------------------------------------------------------------------
# 替换器状态寄存器配对：ref 把 256 组 PLRU 状态展平成标量 state_vec_<S>（每个 3 bit），
# impl 用 SV 数组 state_vec[<S>]（g_replacer[<S>] 生成块内）。名字结构不同，逐组钉死。
# perf 2 级流水：ref io_perf_<i>_value_REG / _REG_1（6 bit）对应 impl
# g_perf[<i>].perf_stage1 / perf_stage2。也逐路钉死。
# --------------------------------------------------------------------------
proc pin { rpath ipath } {
    if {[catch {set_user_match $rpath $ipath} msg]} {
        puts "MATCH_FAIL: $rpath <-> $ipath ($msg)"
        return 0
    }
    return 1
}

set _n 0
# 替换器：256 组，每组 3 bit。impl 把数组寄存器展平成 state_vec_reg[组][位]。
for {set s 0} {$s < 256} {incr s} {
    for {set b 0} {$b < 3} {incr b} {
        set r "r:/WORK/$top/state_vec_${s}_reg\[$b\]"
        set i "i:/WORK/$top/u_core/state_vec_reg\[$s\]\[$b\]"
        incr _n [pin $r $i]
    }
}
# perf：32 路 × 2 级 × 6 bit。impl 展平成 perf_stage{1,2}_reg[事件][位]。
for {set ev 0} {$ev < 32} {incr ev} {
    for {set b 0} {$b < 6} {incr b} {
        incr _n [pin "r:/WORK/$top/io_perf_${ev}_value_REG_reg\[$b\]" \
                     "i:/WORK/$top/u_core/perf_stage1_reg\[$ev\]\[$b\]"]
        incr _n [pin "r:/WORK/$top/io_perf_${ev}_value_REG_1_reg\[$b\]" \
                     "i:/WORK/$top/u_core/perf_stage2_reg\[$ev\]\[$b\]"]
    }
}
puts "PINNED: $_n points"

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
