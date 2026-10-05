# UCLI 脚本：把双例化 tb 里 golden / 重写两棵 Frontend 的实例层次（含模块名）逐行写出，
# 供 scripts/gen_frontend.py --refresh-inst-map 生成 fe_inst_map.tsv / fe_impl_hier.tsv（make hiermap）。
set fh [open ut_gen/hier_dump.txt w]
proc walk {s fh} {
  foreach c [show -instances $s] {
    set full "$s.$c"
    puts $fh "$full\t[show -type $full]"
    walk $full $fh
  }
}
walk tb.u_g_Frontend $fh
walk tb.u_i_Frontend $fh
close $fh
quit
