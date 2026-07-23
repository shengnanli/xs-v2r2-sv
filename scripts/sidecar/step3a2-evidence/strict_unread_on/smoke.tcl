# Step 3A.2 补测 smoke(2026-07-20, 审查 3A.1 判定后的补空)。
# 3A.1 判定采纳: ①默认 -list llength 与 Matching Results 的 unmatched compare 计数**精确一致**
# (3A.1 的 455 是行数统计末尾无换行 off-by-one), -status none 会净化 const/constrained/clock-gate
# 真实 unmatched → 拒作主集; ②3A.1 声称的 -status/-point_type 查询实际未执行 → 本 smoke 补齐;
# ③report_unread_endpoints 三会话 rc=1 已证废, 移除。
# 每 query 产三文件: <name>.ret(返回值原始字节)+<name>.out(redirect stdout 原始字节)+<name>.rc。

set SO $env(SMOKE_OUT)
file mkdir $SO

proc cap {name script} {
    global SO
    set out ""
    set rc [catch {redirect -variable out {set __ret [uplevel 1 $script]}} err]
    if {$rc} { set __ret $err }
    set fh [open "$SO/$name.ret" w]; puts -nonewline $fh $__ret; close $fh
    set fh [open "$SO/$name.out" w]; puts -nonewline $fh $out; close $fh
    set fh [open "$SO/$name.rc" w];  puts -nonewline $fh $rc;  close $fh
    puts "SMOKE\t$name\trc=$rc\tret_llen=[expr {[catch {llength $__ret} _l] ? -1 : $_l}]\tout_len=[string length $out]"
}

# --- 基线(与 3A.1 交叉) ---
cap verification_status   { get_app_var verification_status }
cap status_short          { report_status -short }
cap matched_bbox_list     { report_matched_points -point_type bbox -list }
cap matched_all_list      { report_matched_points -list }
cap unm_ref_default       { report_unmatched_points -reference -list }
cap unm_impl_default      { report_unmatched_points -implementation -list }

# --- 决定1: 分类原始集合(3A.1 缺失, 本次实际执行) ---
cap unm_ref_none          { report_unmatched_points -reference -status none -list }
cap unm_impl_none         { report_unmatched_points -implementation -status none -list }
cap unm_ref_unread        { report_unmatched_points -reference -status unread -list }
cap unm_impl_unread       { report_unmatched_points -implementation -status unread -list }
cap unm_ref_dontv         { report_unmatched_points -reference -status dont_verify -list }
cap unm_impl_dontv        { report_unmatched_points -implementation -status dont_verify -list }
cap unm_ref_const         { report_unmatched_points -reference -status const -list }
cap unm_impl_const        { report_unmatched_points -implementation -status const -list }
cap unm_ref_bbout         { report_unmatched_points -reference -point_type bbox_output -list }
cap unm_impl_bbout        { report_unmatched_points -implementation -point_type bbox_output -list }
cap unm_ref_bbin          { report_unmatched_points -reference -point_type bbox_input -list }
cap unm_impl_bbin         { report_unmatched_points -implementation -point_type bbox_input -list }
# primary input 点型探查(审查: Matching Results 把 primary inputs 与 bbox outputs 合并显示,
# 两个 point type 必须分采; 具体枚举名探查 input/port)
cap unm_ref_pi_input      { report_unmatched_points -reference -point_type input -list }
cap unm_impl_pi_input     { report_unmatched_points -implementation -point_type input -list }
cap unm_ref_pi_port       { report_unmatched_points -reference -point_type port -list }

# --- matched 侧分类探查(Not-Compared unread pair / dont-verify matched pair) ---
cap matched_unread_list   { report_matched_points -status unread -list }
cap matched_dontv_list    { report_matched_points -status dont_verify -list }
cap matched_bbout_list    { report_matched_points -point_type bbox_output -list }

# --- black_boxes 三报告(unresolved/empty 'e'/iface 样本文法) ---
cap black_boxes_default   { report_black_boxes }
cap black_boxes_unresolved { report_black_boxes -unresolved }
cap black_boxes_iface     { report_black_boxes -interface_only }

# --- stats 交叉 ---
cap failing_list          { report_failing_points -list }
cap unverified_list       { report_unverified_points -list }
cap aborted_list          { report_aborted_points -list }
cap passing_list          { report_passing_points -list }
cap dont_verify_rpt       { report_dont_verify_points }
puts "SMOKE32_DONE"
