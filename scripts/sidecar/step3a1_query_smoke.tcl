# Step 3A.1 补测 smoke(2026-07-19, 审查批准的小范围)。
# 修正 3A 的证据缺口: ①redirect -variable 捕获**完整原始字节**(3A 只存了返回值"1")
# ②verification_status 只读 app var ③report_matched_points -point_type bbox(官方结构化黑盒 pair)
# ④report_status -short 交叉 ⑤-list 支持面探查(failing/unverified/aborted)。
# 每 query 产两文件: <name>.ret(catch 返回值原始字节) + <name>.out(redirect stdout 原始字节)
# + <name>.rc。由 runner 汇总 MANIFEST(sha256)。

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
    puts "SMOKE\t$name\trc=$rc\tret_len=[string length $__ret]\tout_len=[string length $out]"
}

# 1. native_verdict 权威源: 只读 app var(SUCCEEDED/FAILED/INCONCLUSIVE/MATCHED/NOT RUN/GUIDE)
cap verification_status      { get_app_var verification_status }
# 2. 官方结构化黑盒 pair(审查指定, 替代前缀过滤)
cap matched_bbox_list        { report_matched_points -point_type bbox -list }
# 3. matched 全量(-list 返回值; 交叉 bbox 子集关系)
cap matched_all_list         { report_matched_points -list }
# 4. unmatched 两侧独立
cap unmatched_ref_list       { report_unmatched_points -reference -list }
cap unmatched_impl_list      { report_unmatched_points -implementation -list }
# 5. black_boxes 报告(redirect 完整字节 → 文法闭环证据)
cap black_boxes_default      { report_black_boxes }
cap black_boxes_unresolved   { report_black_boxes -unresolved }
cap black_boxes_iface        { report_black_boxes -interface_only }
# 6. 统计交叉
cap status_short             { report_status -short }
cap status_full              { report_status }
# 7. stats 各类 -list 支持面
cap failing_list             { report_failing_points -list }
cap failing_default          { report_failing_points }
cap unverified_list          { report_unverified_points -list }
cap aborted_list             { report_aborted_points -list }
cap passing_probe            { report_passing_points -list }
# 8. qualification 采集面
cap dont_verify              { report_dont_verify_points }
cap unread_probe             { report_unread_endpoints }
puts "SMOKE31_DONE"
