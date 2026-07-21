# FM-184 phase 文法解析器 fixture 测试(acceptance gate 1; 四审语义)。tclsh 运行。
# 真实字节 4 形态 + 一/二/三/四审全部负例。四审新增: header/top 绑定、legend 有限文法、
# TECH↔u / DESIGN↔i,e flag-section 绑定、终态必须恰为 TAIL。
set here [file dirname [file normalize [info script]]]
source $here/fm_native_emit.tcl

set pass 0; set fail 0
proc T {name script} {
    global pass fail
    if {[catch {uplevel 1 $script} msg]} { puts "FAIL  $name: $msg"; incr fail } \
    else { puts "PASS  $name"; incr pass }
}
proc expect_err {txt top pat} {
    if {![catch {sidecar_parse_black_boxes $txt $top} msg]} { error "应报错却成功" }
    if {![string match "*$pat*" $msg]} { error "错误类别不符: $msg (期望 $pat)" }
}
proc slurp {f} { set fh [open $f r]; set t [read $fh]; close $fh; return $t }

set C184 "Information: Reporting black boxes for current reference and implementation designs. (FM-184)"
set C249 "Information: No 'black boxes' matched current 'reference and implementation designs'. (FM-249)"
# 合成 header(top=T)
set HDR "**************************************************
Report         : black_boxes
Reference      : r:/WORK/T
Implementation : i:/WORK/T
Version        : V-2023.12-SP3
Date           : Mon Jul 20 00:00:00 2026
**************************************************
"
set SEC_D "####    DESIGN LIBRARY - i:/WORK\nType  Design Name\n----  ----------\n"
set SEC_T "####    TECH LIBRARY - i:/FM_BBOX\nType  Design Name\n----  ----------\n"
set BASE "$HDR$C184\n$SEC_D"
set BASET "$HDR$C184\n$SEC_T"

# ---- 真实字节(终态含回显"1" → TAIL) ----
T empty_real_bku {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/strict_full/black_boxes_default.out] Bku] a b c d e f
    foreach l [list $a $b $c $d $e $f] { if {[llength $l]} { error "空报告应全空" } }
}
T unresolved_real_imsic {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/unresolved_sample/black_boxes_default.out] IMSIC] a b c d e f
    if {[llength $c] != 8 || [llength $d] != 8} { error "u 实例应 8+8" }
    if {[llength $a] || [llength $b] || [llength $e] || [llength $f]} { error "其余类应空" }
}
T empty_flag_real_dcache {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/fmbb_empty/black_boxes_default.out] DCacheWrapper] a b c d e f
    if {[llength $e] != 1 || [llength $f] != 1} { error "e 实例应 1+1" }
}
T iface_real_newifu_default {
    # 五审: 用**默认全量**报告(无 option 头)测 'i' flag 路径
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a1-evidence/assembly_iface/black_boxes_default.out] NewIFU] a b c d e f
    if {[llength $a] != [llength $b] || [llength $a] == 0} { error "i 实例两侧应同数非零" }
}
T iface_filtered_report_rejected {
    # 五审: -interface_only 过滤报告(带 option 头)必须拒——防丢失 unresolved/empty 类
    expect_err [slurp $here/step3a1-evidence/assembly_iface/black_boxes_iface.out] NewIFU bbox_option_header_rejected
}

# ---- 一审负例 ----
T synth_unsupported_flag_s {
    expect_err "${BASE}s      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_unsupported_flag
}
T synth_fm249_with_content {
    expect_err "$HDR$C184\n$C249\ne      Foo\n1\n" T bbox_empty_report_with_content
}
T synth_N_ne_M {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 2\n       ----\n       i:/WORK/T/x\n1\n" T instances_N_ne_M
}
T synth_missing_fm184 {
    expect_err "$HDR$C249\n" T bbox_FM249_wrong_phase
}
T synth_extra_path {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n       i:/WORK/T/y\n1\n" T extra_path_beyond_N
}
T rev1_fm249_indented_block {
    expect_err "$HDR$C184\n$C249\n  u      Foo\n1\n" T bbox_empty_report_with_content
}
T rev2_zero_of_zero_no_249 {
    expect_err "${BASET}u      Foo\n\n       Instances : 0 of 0\n1\n" T instances_zero_of_zero
}
T rev2b_zero_of_zero_design {
    expect_err "${BASE}e      Foo\n\n       Instances : 0 of 0\n1\n" T instances_zero_of_zero
}
T rev3_top_column_extra_path {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\ni:/WORK/T/y\n1\n" T bbox_BLOCKS_unparsed
}
T rev4_duplicate_paths {
    expect_err "${BASE}e      Foo\n\n       Instances : 2 of 2\n       ----\n       i:/WORK/T/x\n       i:/WORK/T/x\n1\n" T duplicate_path
}
T rev5_path_side_mismatch {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       r:/WORK/T/x\n1\n" T path_side_mismatch
}
T rev6_block_outside_section {
    expect_err "$HDR$C184\ne      Foo\n1\n" T bbox_MARKED_unparsed
}

# ---- 二审负例 ----
T v2_dup_fm184 { expect_err "$HDR$C184\n$C184\n" T bbox_duplicate_FM184 }
T v2_dup_fm249 { expect_err "$HDR$C184\n$C249\n1\n$C249\n" T bbox_duplicate_FM249 }
T v2_banana_library {
    expect_err "$HDR$C184\n####    BANANA LIBRARY - i:/WORK\n" T bbox_bad_section_header
}
T v2_missing_table_header {
    expect_err "$HDR$C184\n####    DESIGN LIBRARY - i:/WORK\nu      Foo\n" T bbox_section_missing_table_header
}
T v2_missing_separator {
    expect_err "$HDR$C184\n####    DESIGN LIBRARY - i:/WORK\nType  Design Name\nu      Foo\n" T bbox_section_missing_separator
}
T v2_section_without_blocks {
    expect_err "${BASE}####    DESIGN LIBRARY - r:/WORK\n" T bbox_section_without_blocks
}
T v2_dangling_section {
    expect_err "$HDR$C184\n####    DESIGN LIBRARY - i:/WORK\n" T bbox_end_phase_not_TAIL
}
T v2_unknown_information_line {
    expect_err "$HDR$C184\nInformation: something else (FM-999)\n" T bbox_unknown_information_line
}

# ---- 三审负例 ----
T v3_fake_fm184_text { expect_err "${HDR}Information: attacker (FM-184)\n" T bbox_unknown_information_line }
T v3_fake_fm249_text {
    expect_err "$HDR$C184\nInformation: attacker says empty (FM-249)\n" T bbox_unknown_information_line
}
T v3_design_library_fmbbox_mispair {
    expect_err "$HDR$C184\n####    DESIGN LIBRARY - i:/FM_BBOX\n" T bbox_section_kind_root_mismatch
}
T v3_tech_library_work_mispair {
    expect_err "$HDR$C184\n####    TECH LIBRARY - i:/WORK\n" T bbox_section_kind_root_mismatch
}
T v3_content_after_tail_echo {
    set t "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n"
    append t "####    DESIGN LIBRARY - r:/WORK\n"
    expect_err $t T bbox_content_after_tail_echo
}
T v3_cross_flag_duplicate_path {
    set t "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n\n"
    append t "i      Bar\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n"
    expect_err $t T duplicate_path
}

# ---- 四审负例 ----
T v4_tech_with_i_flag {
    expect_err "${BASET}i      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_flag_section_mismatch
}
T v4_tech_with_e_flag {
    expect_err "${BASET}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_flag_section_mismatch
}
T v4_design_with_u_flag {
    expect_err "${BASE}u      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_flag_section_mismatch
}
T v4_empty_no_tail_echo {
    # FM-184+FM-249 但缺最终整数回显 → 不得返回六空集合
    expect_err "$HDR$C184\n$C249\n" T bbox_end_phase_not_TAIL
}
T v4_nonempty_no_tail_echo {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n" T bbox_end_phase_not_TAIL
}
T v4_wrong_report_name {
    set h [string map {black_boxes failing_points} $HDR]
    expect_err "$h$C184\n$C249\n1\n" T bbox_wrong_report_name
}
T v4_wrong_reference_top {
    expect_err "$HDR$C184\n$C249\n1\n" WrongTop bbox_wrong_reference_top
}
T v4_header_incomplete {
    expect_err "$C184\n$C249\n1\n" T bbox_header_incomplete_before_FM184
}
T v4_unknown_legend_line {
    expect_err "$HDR$C184\n|  fake legend row                                  |\n$C249\n1\n" T bbox_unknown_legend_line
}
T v4_positive_synth_with_tail {
    lassign [sidecar_parse_black_boxes \
        "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T] a b c d e f
    if {$f ne {i:/WORK/T/x}} { error "empty_impl 应恰为该路径" }
}
# ---- 五审负例 ----
T v5_option_header_rejected {
    set h "**************************************************
Report         : black_boxes
                 -interface_only
Reference      : r:/WORK/T
Implementation : i:/WORK/T
Version        : X
Date           : Mon
**************************************************
"
    expect_err "$h$C184\n$C249\n1\n" T bbox_option_header_rejected
}
T v5_header_out_of_order {
    set h "**************************************************
Reference      : r:/WORK/T
Report         : black_boxes
Implementation : i:/WORK/T
Version        : X
Date           : Mon
**************************************************
"
    expect_err "$h$C184\n$C249\n1\n" T bbox_header_order
}
T v5_header_duplicate {
    set h "**************************************************
Report         : black_boxes
Report         : black_boxes
Reference      : r:/WORK/T
Implementation : i:/WORK/T
Version        : X
Date           : Mon
**************************************************
"
    expect_err "$h$C184\n$C249\n1\n" T bbox_header_order
}
T v5_tail_zero {
    expect_err "$HDR$C184\n$C249\n0\n" T bbox_empty_report_with_content
}
T v5_tail_negative {
    expect_err "$HDR$C184\n$C249\n-7\n" T bbox_empty_report_with_content
}
T v5_tail_two_ones {
    expect_err "$HDR$C184\n$C249\n1\n1\n" T bbox_content_after_tail_echo
}
T v5_empty_no_tail {
    expect_err "$HDR$C184\n$C249\n" T bbox_end_phase_not_TAIL
}
# ---- 十二审(combo-flag: `e *` unlinked 修饰符, 窄范围)----
T v12_combo_e_star_positive {
    # `e *` = empty+unlinked: 解析成功, primary=e 入 empty(er/ei), 且 unlinked 记入 sr/si
    lassign [sidecar_parse_black_boxes \
        "${BASE}e *    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T] a b c d e f g h
    if {$f ne {i:/WORK/T/x}} { error "empty_impl 应含该路径, 得 [list $f]" }
    if {$h ne {i:/WORK/T/x}} { error "unlinked_impl 应含该路径(不丢弃), 得 [list $h]" }
}
T v12_combo_u_star_tech {
    lassign [sidecar_parse_black_boxes \
        "${BASET}u *    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T] a b c d e f g h
    if {$d ne {i:/WORK/T/x}} { error "unresolved_impl 应含该路径" }
    if {$h ne {i:/WORK/T/x}} { error "unlinked_impl 应含该路径" }
}
T v12_two_primary_flags_rejected {
    expect_err "${BASE}e u    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_multiple_primary_flags
}
T v12_unknown_modifier_rejected {
    # 非文档化 flag(@)拒——不泛化为"忽略未知 flag"
    expect_err "${BASE}e @    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_unsupported_flag
}
T v12_star_alone_no_primary_rejected {
    expect_err "${BASE}*    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_no_primary_flag
}
T v12_unsupported_s_flag_still_rejected {
    # s(set_black_box)等主类外 flag 仍拒(保持 fail-closed)
    expect_err "${BASE}s    Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n" T bbox_unsupported_flag
}
T v12_bare_instances_zero_accepted {
    # 真实零实例块 `Instances : 0`(黑盒设计存在但未实例化): 解析成功, 记0路径, 非畸形
    lassign [sidecar_parse_black_boxes \
        "${BASE}e *    Foo\n\n       Instances : 0\n\n1\n" T] a b c d e f g h
    if {[llength $e]||[llength $f]||[llength $g]||[llength $h]} { error "零实例应无路径" }
}
T v12_two_zero_blocks_then_tail {
    lassign [sidecar_parse_black_boxes \
        "${BASE}e *    Foo\n\n       Instances : 0\n\ne *    Bar\n\n       Instances : 0\n\n1\n" T] a b c d e f
    if {[llength $e]||[llength $f]} { error "应无路径" }
}
puts "$pass/[expr {$pass+$fail}] passed"
if {$fail} { exit 1 }
