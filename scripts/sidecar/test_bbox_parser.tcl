# FM-184 状态机解析器 fixture 测试(acceptance gate 1)。tclsh 运行, 不依赖 fm_shell。
# 真实字节: 3A.2 证据的空(FM-184+FM-249 共存)/'u' 非空/'e' 非空 + 3A.1 的 'i' 非空;
# 合成负例: 未支持 flag / FM-249 带实例块 / N!=M / 缺 FM-184 / 超 N 路径。
set here [file dirname [file normalize [info script]]]
source $here/fm_native_emit.tcl

set pass 0; set fail 0
proc T {name script} {
    global pass fail
    if {[catch {uplevel 1 $script} msg]} {
        puts "FAIL  $name: $msg"; incr fail
    } else {
        puts "PASS  $name"; incr pass
    }
}
proc expect_err {txt pat} {
    if {![catch {sidecar_parse_black_boxes $txt} msg]} { error "应报错却成功" }
    if {![string match "*$pat*" $msg]} { error "错误类别不符: $msg (期望 $pat)" }
}
set C184 "Information: Reporting black boxes for current reference and implementation designs. (FM-184)"
set C249 "Information: No 'black boxes' matched current 'reference and implementation designs'. (FM-249)"
proc slurp {f} { set fh [open $f r]; set t [read $fh]; close $fh; return $t }

# ---- 真实字节 ----
T empty_real_bku {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/strict_full/black_boxes_default.out]] a b c d e f
    foreach l [list $a $b $c $d $e $f] { if {[llength $l]} { error "空报告应全空" } }
}
T unresolved_real_imsic {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/unresolved_sample/black_boxes_default.out]] a b c d e f
    if {[llength $c] != 8 || [llength $d] != 8} { error "u 实例应 8+8, 得 [llength $c]+[llength $d]" }
    if {[llength $a] || [llength $b] || [llength $e] || [llength $f]} { error "其余类应空" }
}
T empty_flag_real_dcache {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a2-evidence/fmbb_empty/black_boxes_default.out]] a b c d e f
    if {[llength $e] != 1 || [llength $f] != 1} { error "e 实例应 1+1" }
    if {[llength $a] || [llength $b] || [llength $c] || [llength $d]} { error "其余类应空" }
}
T iface_real_newifu {
    lassign [sidecar_parse_black_boxes \
        [slurp $here/step3a1-evidence/assembly_iface/black_boxes_iface.out]] a b c d e f
    if {[llength $a] != [llength $b] || [llength $a] == 0} { error "i 实例应两侧同数非零, 得 [llength $a]+[llength $b]" }
    if {[llength $c] || [llength $d] || [llength $e] || [llength $f]} { error "其余类应空" }
}

# ---- 合成负例 ----
set BASE {Information: Reporting black boxes for current reference and implementation designs. (FM-184)

##################################################################
####    DESIGN LIBRARY - i:/WORK
##################################################################
Type  Design Name
----  ----------
}
T synth_unsupported_flag_s {
    expect_err "${BASE}s      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n" bbox_unsupported_flag
}
T synth_fm249_with_content {
    set t "$C184\n$C249\n"
    append t "e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n"
    expect_err $t bbox_empty_report_with_content
}
T synth_N_ne_M {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 2\n       ----\n       i:/WORK/T/x\n" instances_N_ne_M
}
T synth_missing_fm184 {
    expect_err "$C249\n" bbox_FM249_wrong_phase
}
T synth_extra_path {
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n       i:/WORK/T/y\n" extra_path_beyond_N
}
T synth_nonempty_no_blocks {
    expect_err "$C184\n" bbox_nonempty_claim_but_no_blocks
}

# ---- 验收一审四个独立复现(此前宽松扫描全部误收) ----
T rev1_fm249_indented_block {
    # FM-249 + 缩进的非空 block: 缩进 flag 行此前被静默跳过→误收为空集; 现 fail-closed 拒
    set t "$C184\n$C249\n"
    append t "  u      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n"
    expect_err $t bbox_empty_report_with_content
}
T rev2_zero_of_zero_no_249 {
    expect_err "${BASE}u      Foo\n\n       Instances : 0 of 0\n" instances_zero_block
}
T rev3_top_column_extra_path {
    # N=1 后追加顶格路径: 此前被静默忽略; 现落白名单外 error
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\ni:/WORK/T/y\n" bbox_BLOCKS_unparsed
}
T rev4_duplicate_paths {
    # N=2 两条重复路径: 此前 lsort -unique 折叠成一条; 现 error
    expect_err "${BASE}e      Foo\n\n       Instances : 2 of 2\n       ----\n       i:/WORK/T/x\n       i:/WORK/T/x\n" duplicate_path
}
T rev5_path_side_mismatch {
    # section 是 i:/WORK, 路径却是 r: → namespace 不一致
    expect_err "${BASE}e      Foo\n\n       Instances : 1 of 1\n       ----\n       r:/WORK/T/x\n" path_side_mismatch
}
T rev6_block_outside_section {
    expect_err "$C184\ne      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n" bbox_MARKED_unparsed
}
# ---- 验收二审负例(phase 文法) ----
T v2_dup_fm184 {
    expect_err "$C184\n$C184\n" bbox_duplicate_FM184
}
T v2_dup_fm249 {
    expect_err "$C184\n$C249\n$C249\n" bbox_duplicate_FM249
}
T v2_banana_library {
    expect_err "$C184\n####    BANANA LIBRARY - i:/WORK\n" bbox_bad_section_header
}
T v2_side_garbage {
    expect_err "$C184\n####    TECH LIBRARY - i:garbage\n" bbox_bad_section_header
}
T v2_fm249_with_section {
    expect_err "$C184\n$C249\n####    DESIGN LIBRARY - i:/WORK\n" bbox_empty_report_with_content
}
T v2_missing_table_header {
    expect_err "$C184\n####    DESIGN LIBRARY - i:/WORK\nu      Foo\n" bbox_section_missing_table_header
}
T v2_missing_separator {
    expect_err "$C184\n####    DESIGN LIBRARY - i:/WORK\nType  Design Name\nu      Foo\n" bbox_section_missing_separator
}
T v2_section_without_blocks {
    set t "$C184\n####    DESIGN LIBRARY - i:/WORK\nType  Design Name\n----  ----------\n"
    append t "####    DESIGN LIBRARY - r:/WORK\n"
    expect_err $t bbox_section_without_blocks
}
T v2_dangling_section {
    expect_err "$C184\n####    DESIGN LIBRARY - i:/WORK\n" bbox_dangling_section
}
T v2_unknown_information_line {
    expect_err "$C184\nInformation: something else (FM-999)\n" bbox_unknown_information_line
}
# ---- 验收三审负例 ----
T v3_fake_fm184_text {
    # 伪造 marker 文本(非规范全文)不再被认作 FM-184 → 落 unknown_information_line
    expect_err "Information: attacker (FM-184)\n" bbox_unknown_information_line
}
T v3_fake_fm249_text {
    # 伪造 FM-249(可产六空集合的攻击面)→ 拒
    expect_err "$C184\nInformation: attacker says empty (FM-249)\n" bbox_unknown_information_line
}
T v3_design_library_fmbbox_mispair {
    expect_err "$C184\n####    DESIGN LIBRARY - i:/FM_BBOX\n" bbox_section_kind_root_mismatch
}
T v3_tech_library_work_mispair {
    expect_err "$C184\n####    TECH LIBRARY - i:/WORK\n" bbox_section_kind_root_mismatch
}
T v3_content_after_tail_echo {
    # 整数回显后继续 section/block → 拒(TAIL 终态)
    set t "$C184\n####    DESIGN LIBRARY - i:/WORK\nType  Design Name\n----  ----------\n"
    append t "e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n1\n"
    append t "####    DESIGN LIBRARY - r:/WORK\n"
    expect_err $t bbox_content_after_tail_echo
}
T v3_cross_flag_duplicate_path {
    # 同一 (side,path) 跨 i/u/e 类别重复 → 拒
    set t "$C184\n####    DESIGN LIBRARY - i:/WORK\nType  Design Name\n----  ----------\n"
    append t "e      Foo\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n\n"
    append t "i      Bar\n\n       Instances : 1 of 1\n       ----\n       i:/WORK/T/x\n"
    expect_err $t duplicate_path
}
puts "$pass/[expr {$pass+$fail}] passed"
if {$fail} { exit 1 }
