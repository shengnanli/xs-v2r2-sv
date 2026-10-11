# PTWNewFilter FM「匹配前」钉点 —— 自动生成：scripts/gen_ptwnewfilter.py（勿手改）
#
# 只钉三张过滤表里的 inflight_counter（在途计数，只喂性能计数器与断言，两侧都没人读）：
# 它们没有功能签名，FM 配不上，落成两侧 unmatched unread；钉上之后由 vmucp 照比。
# 其余寄存器 FM 自己按名/按功能配上（不钉时实测 unmatched 0），passing 对上模型即配全。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），逐条数返回值；
# 拒一条或总数不等于字面整数就 error（safe interp 里不用 exit）。进 fm.log 的输出一律 ASCII。
set ::PNF_PIN_EXPECT 10
set ::PNF_PIN_OK 0
set ::PNF_PIN_BAD 0
proc pnf_pin {r m} {
  if {[set_user_match $r $m]} { incr ::PNF_PIN_OK } else {
    incr ::PNF_PIN_BAD
    if {$::PNF_PIN_BAD <= 10} { puts "PNF_PIN_FAIL: $r <-> $m" }
  }
}
puts "PNF_PIN_BEGIN PTWNewFilter expect=$::PNF_PIN_EXPECT"
pnf_pin r:/WORK/PTWNewFilter/load_filter_load_entry/inflight_counter_reg\[0\] i:/WORK/PTWNewFilter/u_core/load_filter/u_core/inflight_counter_reg\[0\]
pnf_pin r:/WORK/PTWNewFilter/load_filter_load_entry/inflight_counter_reg\[1\] i:/WORK/PTWNewFilter/u_core/load_filter/u_core/inflight_counter_reg\[1\]
pnf_pin r:/WORK/PTWNewFilter/load_filter_load_entry/inflight_counter_reg\[2\] i:/WORK/PTWNewFilter/u_core/load_filter/u_core/inflight_counter_reg\[2\]
pnf_pin r:/WORK/PTWNewFilter/load_filter_load_entry/inflight_counter_reg\[3\] i:/WORK/PTWNewFilter/u_core/load_filter/u_core/inflight_counter_reg\[3\]
pnf_pin r:/WORK/PTWNewFilter/store_filter_store_entry/inflight_counter_reg\[0\] i:/WORK/PTWNewFilter/u_core/store_filter/u_core/inflight_counter_reg\[0\]
pnf_pin r:/WORK/PTWNewFilter/store_filter_store_entry/inflight_counter_reg\[1\] i:/WORK/PTWNewFilter/u_core/store_filter/u_core/inflight_counter_reg\[1\]
pnf_pin r:/WORK/PTWNewFilter/store_filter_store_entry/inflight_counter_reg\[2\] i:/WORK/PTWNewFilter/u_core/store_filter/u_core/inflight_counter_reg\[2\]
pnf_pin r:/WORK/PTWNewFilter/prefetch_filter_prefetch_entry/inflight_counter_reg\[0\] i:/WORK/PTWNewFilter/u_core/prefetch_filter/u_core/inflight_counter_reg\[0\]
pnf_pin r:/WORK/PTWNewFilter/prefetch_filter_prefetch_entry/inflight_counter_reg\[1\] i:/WORK/PTWNewFilter/u_core/prefetch_filter/u_core/inflight_counter_reg\[1\]
pnf_pin r:/WORK/PTWNewFilter/prefetch_filter_prefetch_entry/inflight_counter_reg\[2\] i:/WORK/PTWNewFilter/u_core/prefetch_filter/u_core/inflight_counter_reg\[2\]
puts "PNF_PIN_END PTWNewFilter ok=$::PNF_PIN_OK bad=$::PNF_PIN_BAD"
if {$::PNF_PIN_BAD != 0} { error "PNF_PIN_MISS=$::PNF_PIN_BAD" }
if {$::PNF_PIN_OK != 10} { error "PNF_PIN_COUNT=$::PNF_PIN_OK expect=10" }
