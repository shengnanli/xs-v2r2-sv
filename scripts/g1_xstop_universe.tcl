# g1_xstop_universe.tcl —— 用 FM 自身的 elaborated hierarchy 导出 G1 设计 universe。
#
# codex 0142 §34：源码正则可达分析不够——没跑 `+define+SYNTHESIS` 预处理，可能把
# inactive 的 difftest/debug instrumentation 计进来，也可能漏掉参数化/非标准排版的实例。
# 这里用与 proof 相同的 read_sverilog -define {SYNTHESIS}，以 **XSTop**（设计顶层，
# 非 SimTop 仿真顶层）为根，导出工具真正 elaborate 出来的设计集合。
#
# 输入(env)：G1_GOLDEN  golden RTL 目录
#            OUT_DIR    输出目录
# 输出：$OUT_DIR/xstop_designs.txt    report_designs 原文
#       $OUT_DIR/xstop_hierarchy.txt  report_hierarchy 原文（例化层次）
#       $OUT_DIR/xstop_blackboxes.txt report_black_boxes 原文（未解析者=设计外边界）

set golden $env(G1_GOLDEN)
set outdir $env(OUT_DIR)
file mkdir $outdir

set_app_var hdlin_unresolved_modules black_box

# 读全部 golden RTL（.sv 与 .v 都读；.v 里是厂商行为模型叶子）
set srcs [concat [lsort [glob -nocomplain $golden/*.sv]] \
                 [lsort [glob -nocomplain $golden/*.v]]]
puts "XSTOP_UNIVERSE: reading [llength $srcs] files with -define SYNTHESIS"
read_sverilog -container r -libname WORK -define {SYNTHESIS} $srcs

set_top r:/WORK/XSTop

redirect $outdir/xstop_designs.txt    {report_designs}
redirect $outdir/xstop_hierarchy.txt  {report_hierarchy}
redirect $outdir/xstop_blackboxes.txt {report_black_boxes}

puts "XSTOP_UNIVERSE: done"
exit
