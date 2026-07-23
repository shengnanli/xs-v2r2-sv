# LoadQueue FM 钉点（FM 审计 2026-07）
# 本模块 FM 两侧的 6 个子队列用**同一份 golden 定义**（Makefile 注释），差异只在
# 实例路径前缀（ref: loadQueueReplay/… vs impl: u_core/u_lq_replay/…）。签名匹配
# 在数万个同构寄存器上大面积失败（4.9 万 unmatched 传染）。用 set_compare_rule
# 做层次前缀映射，让名字匹配直接命中；规则须在 setup 模式设置，脚本随后重新 match。
setup
foreach {f t} {
  {^u_core/u_lq_rar/}    {loadQueueRAR/}
  {^u_core/u_lq_raw/}    {loadQueueRAW/}
  {^u_core/u_lq_replay/} {loadQueueReplay/}
  {^u_core/u_vlq/}       {virtualLoadQueue/}
  {^u_core/u_exc_buf/}   {exceptionBuffer/}
  {^u_core/u_unc_buf/}   {uncacheBuffer/}
  {^u_core/}             {}
} {
  foreach ty {cell net port pin} {
    catch {set_compare_rule "i:/WORK/$top" -type $ty -from $f -to $t}
  }
}
puts "LOADQUEUE_PINS: hierarchy compare rules applied"
