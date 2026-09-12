# g1_xstop_universe_bbox.tcl —— 边界黑盒版的 XSTop 设计 universe 提取（codex 0143）。
#
# 与全展开版（g1_xstop_universe.tcl）的唯一区别：**不读入已通过 leaf audit 的排除类
# 叶子源文件**（vendor macro / array·sram wrapper / 纯 behavioral RAM），让它们经
# hdlin_unresolved_modules=black_box 成为边界。目的只是加速 universe 提取——
# ★这些黑盒设置禁止进入任何 Formal signoff 配置或 allow 声明（codex 0143 §1）★。
#
# 名单来源：docs/g1_blackbox_candidates.tsv，每条都经机械 leaf audit 确认其
# 不再例化排除闭包之外的 module（否则黑盒会截断真实设计层次）。
#
# 输入(env)：G1_GOLDEN / OUT_DIR / BBOX_LIST
# 输出：$OUT_DIR/{xstop_designs,xstop_hierarchy,xstop_blackboxes}.txt + PROVENANCE.tsv

set golden $env(G1_GOLDEN)
set outdir $env(OUT_DIR)
set bblist $env(BBOX_LIST)
file mkdir $outdir

set_app_var hdlin_unresolved_modules black_box

source [file dirname [info script]]/_universe_guard.tcl
u_allow_x_interpretation

# 读黑盒名单（module 名 → 跳过其定义文件）
set bb {}
set fh [open $bblist r]
foreach ln [split [read $fh] "\n"] {
    if {[string match "#*" $ln] || [string trim $ln] eq ""} { continue }
    set c [split $ln "\t"]
    lappend bb [lindex $c 0]
    set bbfile([lindex $c 2]) 1
}
close $fh
puts "BBOX_UNIVERSE: blackbox 名单 [llength $bb] 项，跳过 [array size bbfile] 个定义文件"

# 读入除黑盒定义文件之外的全部 golden 源
set srcs {}
foreach f [concat [lsort [glob -nocomplain $golden/*.sv]] [lsort [glob -nocomplain $golden/*.v]]] {
    if {[info exists bbfile([file tail $f])]} { continue }
    lappend srcs $f
}
puts "BBOX_UNIVERSE: reading [llength $srcs] files with -define SYNTHESIS (top=XSTop)"
read_sverilog -container r -libname WORK -define {SYNTHESIS} $srcs
u_set_top r:/WORK/XSTop

redirect $outdir/xstop_designs.txt    {report_designs}
redirect $outdir/xstop_hierarchy.txt  {report_hierarchy}
redirect $outdir/xstop_blackboxes.txt {report_black_boxes}

# provenance：命令 / define / top / 工具版本 / 名单，保证可复算
set pf [open $outdir/PROVENANCE.tsv w]
puts $pf "kind\tboundary_blackbox_universe"
puts $pf "top\tr:/WORK/XSTop"
puts $pf "define\tSYNTHESIS"
puts $pf "read_cmd\tread_sverilog -container r -libname WORK -define {SYNTHESIS} <srcs>"
puts $pf "n_src_files\t[llength $srcs]"
puts $pf "n_blackbox_modules\t[llength $bb]"
puts $pf "hdlin_unresolved_modules\t[get_app_var hdlin_unresolved_modules]"
puts $pf "tool_version\t[get_app_var sh_product_version]"
puts $pf "bbox_list_file\t$bblist"
close $pf

u_check_reports $outdir
puts "BBOX_UNIVERSE: done"
exit
