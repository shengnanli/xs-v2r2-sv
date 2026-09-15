# fm_pins_pre.tcl 的冒烟验收 —— 约 2.5 分钟，不跑证明
# ============================================================================
# 【为什么要单独有这个】
#   钉点对不对，唯一的真判据是"两侧 elaborate 出来的名字能不能配上"。拿整条
#   官方证明去验要约 19 分钟才到 Matching（本目标实测），而且 Matching 本身
#   不收敛（docs/predictor_fm_scaling_wall.md），不适合当反馈回路。
#   本脚本只做证明的**前半段**：读两侧、set_top、在与 sidecar **同一套白名单**
#   的受限 safe interp 里执行 fm_pins_pre.tcl，看它自己的 fail-closed 响不响。
#
# 【为什么可以黑盒子模块】
#   GHV 的 256 个点两侧都在各自**顶层设计**里（golden 的 ghv_<n>_reg 在
#   Predictor 本体，可读核的 ghv_q_reg[n] 在 xs_Predictor_core），与任何子模块
#   无关。黑盒子模块只是省掉读 90 多个 golden 文件的时间，不影响这批名字。
#   ★这不是证明★：它证不了任何等价性，只验"钉点能不能落地"。签核仍然只认
#   scripts/run_proof.sh 的官方产物。
#
# 【跑法】
#   cd <repo> && fm_shell -64 -work_path <tmpdir> -file verif/ut/Predictor/fm_pins_smoke.tcl
#   期望输出：PREDICTOR_PINS: 256 / 256 pinned, 0 missed   后跟  SMOKE_OK
#   任何 SMOKE_FAIL / 少于 256 都表示名字或结构已经漂了。
# ============================================================================
if {![info exists env(XSSV_HOME)]} { error "SMOKE: 需要 XSSV_HOME=<repo>" }
if {![info exists env(GOLDEN_RTL)]} { error "SMOKE: 需要 GOLDEN_RTL=<G1-canonical/golden-rtl>" }
set W $env(XSSV_HOME)
set G $env(GOLDEN_RTL)

set_app_var hdlin_unresolved_modules black_box
read_sverilog -r -define {SYNTHESIS} "$G/Predictor.sv"
if {[set_top r:/WORK/Predictor] == 0} { error "SMOKE: ref set_top 失败" }
read_sverilog -i -define {SYNTHESIS} "$W/rtl/frontend/Predictor.sv"
if {[set_top i:/WORK/Predictor] == 0} { error "SMOKE: impl set_top 失败" }

# 与 scripts/sidecar/fm_native_emit.tcl 的 sidecar_pin_source 逐字同一套 alias。
# 改那边必须同步改这里，否则冒烟过了、真跑却因为缺命令而 error。
set ip [interp create -safe]
foreach c {set_user_match set_app_var get_app_var puts report_unmatched_points \
           report_matched_points set_constant remove_constant \
           current_design find_designs find_cells \
           setup set_dont_verify_points set_compare_rule match verify} {
  if {[info commands $c] ne ""} { interp alias $ip $c {} $c }
}
interp eval $ip [list set top Predictor]
set fh [open "$W/verif/ut/Predictor/fm_pins_pre.tcl" rb]
set buf [read $fh]
close $fh
if {[catch {interp eval $ip [encoding convertfrom utf-8 $buf]} m]} {
  puts "SMOKE_FAIL: $m"
  exit 1
}
puts "SMOKE_OK"
exit 0
