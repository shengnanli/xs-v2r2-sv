# Step 3A: Formality 查询 smoke(2026-07-19, 审查批准 GO)。
# 目的: 在真实 FM 会话里实证 native facts 每个字段的**确切采集命令、返回类型、数量关系、失败行为**,
# 产出字段→API 表。只查询+dump 原始输出, 不写 sidecar(STEP3B 仍 NO-GO)。
# 用法: 由 step3a_run.sh 在标准 fm_eq.tcl 会话完成 verify 后 source(环境变量 SMOKE_OUT 指输出目录)。

set SO $env(SMOKE_OUT)
file mkdir $SO

proc dump {name script} {
    global SO
    set rc [catch {uplevel 1 $script} out]
    set fh [open "$SO/$name.txt" w]
    puts $fh "== rc: $rc =="
    puts $fh $out
    close $fh
    puts "SMOKE\t$name\trc=$rc\tlen=[string length $out]"
}

# ---- 候选 API 逐个实测(含返回类型探查) ----
# 1. matched points: 文档称返回 pairs
dump matched_points_list       { report_matched_points -list }
dump matched_points_default    { report_matched_points }
# 2. unmatched points: 文档称两侧独立列表
dump unmatched_ref_list        { report_unmatched_points -reference -list }
dump unmatched_impl_list       { report_unmatched_points -implementation -list }
dump unmatched_default         { report_unmatched_points }
# 3. black boxes: 无 -list, 探查可用选项与输出格式
dump black_boxes_default       { report_black_boxes }
dump black_boxes_help          { help report_black_boxes }
dump black_boxes_iface         { report_black_boxes -interface_only }
dump black_boxes_unresolved    { report_black_boxes -unresolved }
# 4. 统计与 verify 状态(供计数交叉)
dump verify_status             { report_status }
dump failing_points            { report_failing_points }
dump unverified_points         { report_unverified_points }
# 5. dont_verify / 常量等 qualification 观察面
dump dont_verify               { report_dont_verify_points }
dump constants                 { report_constants }
# 6. Tcl 层能否拿到结构化列表(find 系)
dump find_bb_ref               { find_cells r:/WORK/* -filter "is_black_box==true" }
dump find_bb_impl              { find_cells i:/WORK/* -filter "is_black_box==true" }
puts "SMOKE_DONE"
