# NewDispatch 上下文里唯一的叶名差异配对（只 set_user_match，不约束 ref，FM 仍要证明两者等价）。
# golden BusyTable 的 x0 位是单独一个 `reg table_r`（其余是 table_r_1..）；重写核是 busy_reg[0]。
# standalone BusyTable 签核时两者按签名配上了（unmatched 0）；在 NewDispatch 上下文里 ref 侧
# 被父级写口门控判成 DFF0X、impl 侧是 DFF0，FM 的签名匹配不把两类常量寄存器配对，故显式钉一次。
# fail-closed（test_fm_pins_wellformed P2/P3）：set_user_match 对不存在的名字只返回 0、不抛异常，
# 所以必须数返回值；期望数量字面声明为 1，钉不上就 error（fm_shell 不进 verify、不出 receipt）。
set _nd_expect 1
set _nd_n 0
if {[set_user_match r:/WORK/NewDispatch/intBusyTable/table_r_reg i:/WORK/NewDispatch/intBusyTable/u_core/busy_reg\[0\]]} {
  incr _nd_n
}
puts "ND_PIN_END n=$_nd_n expect=$_nd_expect"
if {$_nd_n != $_nd_expect} { error "ND_PIN_MISS n=$_nd_n expect=$_nd_expect" }
