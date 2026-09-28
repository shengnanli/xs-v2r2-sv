# IntRegFilePart0..3 FM「匹配前」钉点 —— 自动生成：scripts/gen_intregfile.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟：
#   ref  mem_<k>_reg[b]                  <-> impl u_core/mem_reg[k][b]        k=1..223, b=0..15
#   ref  io_readPorts_<r>_data_REG_reg[b] <-> impl u_core/raddr_q_reg[r][b]    r=0..10, b=0..7
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数 3656（= golden 寄存器位数）就 error（safe interp 里不用 exit）。
# 四个变体结构逐字相同，按 $top 取路径，同一份钉点对四个 top 都成立。进 fm.log 的输出一律 ASCII。
set ::INTRF_PIN_EXPECT 3656
set ::INTRF_PIN_OK 0
set ::INTRF_PIN_BAD 0
proc intrf_pin {r i} {
  if {[set_user_match $r $i]} { incr ::INTRF_PIN_OK } else {
    incr ::INTRF_PIN_BAD
    if {$::INTRF_PIN_BAD <= 10} { puts "INTRF_PIN_FAIL: $r <-> $i" }
  }
}
puts "INTRF_PIN_BEGIN $top expect=$::INTRF_PIN_EXPECT"
for {set k 1} {$k <= 223} {incr k} {
  for {set b 0} {$b < 16} {incr b} {
    intrf_pin "r:/WORK/$top/mem_${k}_reg\[$b\]" "i:/WORK/$top/u_core/mem_reg\[$k\]\[$b\]"
  }
}
for {set r 0} {$r < 11} {incr r} {
  for {set b 0} {$b < 8} {incr b} {
    intrf_pin "r:/WORK/$top/io_readPorts_${r}_data_REG_reg\[$b\]" "i:/WORK/$top/u_core/raddr_q_reg\[$r\]\[$b\]"
  }
}
puts "INTRF_PIN_END $top ok=$::INTRF_PIN_OK bad=$::INTRF_PIN_BAD"
if {$::INTRF_PIN_BAD != 0} { error "INTRF_PIN_MISS=$::INTRF_PIN_BAD" }
if {$::INTRF_PIN_OK != 3656} { error "INTRF_PIN_COUNT=$::INTRF_PIN_OK expect=3656" }
