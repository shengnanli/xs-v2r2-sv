# RequestBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_reqbuf.py（勿手改）
#
# 只钉 perf 专用的 12 个 1 位寄存器（每个表项 3 个：RegNext(valid) / 清零脉冲 / 直方图采样），
#   golden  REG / REG_<2k> / REG_<2k+1> / enable_REG[_k]   <->  重写  u_core/validPrev / timerClear / histValidPrev [k]
# 它们只被 perf 打印与 ifndef SYNTHESIS 的 assert 读（两侧对称的未读寄存器），FM 不给未读寄存器做签名配对，
# 名字又完全不同，不钉就两侧各自落单。其余寄存器（含 4 个对称表项）FM 按名 / 签名全部自动配上：
# 诊断跑（不产 receipt）实测 0(0) unmatched compare points。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面位数就 error。进 fm.log 的输出一律 ASCII。
# 本目录还有 FastArbiter_2 / Queue1_ChosenQBundle 两个 FM 目标：钉点只对 top 为 RequestBuffer 时生效。
if {$top eq "RequestBuffer"} {
set ::RB_PIN_EXPECT 12
set ::RB_PIN_OK 0
set ::RB_PIN_BAD 0
proc rb_pin {r i} {
  if {[set_user_match $r $i]} { incr ::RB_PIN_OK } else {
    incr ::RB_PIN_BAD
    if {$::RB_PIN_BAD <= 10} { puts "RB_PIN_FAIL: $r <-> $i" }
  }
}
puts "RB_PIN_BEGIN RequestBuffer expect=$::RB_PIN_EXPECT"
rb_pin r:/WORK/RequestBuffer/REG_reg i:/WORK/RequestBuffer/u_core/validPrev_reg\[0\]
rb_pin r:/WORK/RequestBuffer/REG_1_reg i:/WORK/RequestBuffer/u_core/timerClear_reg\[0\]
rb_pin r:/WORK/RequestBuffer/enable_REG_reg i:/WORK/RequestBuffer/u_core/histValidPrev_reg\[0\]
rb_pin r:/WORK/RequestBuffer/REG_2_reg i:/WORK/RequestBuffer/u_core/validPrev_reg\[1\]
rb_pin r:/WORK/RequestBuffer/REG_3_reg i:/WORK/RequestBuffer/u_core/timerClear_reg\[1\]
rb_pin r:/WORK/RequestBuffer/enable_REG_1_reg i:/WORK/RequestBuffer/u_core/histValidPrev_reg\[1\]
rb_pin r:/WORK/RequestBuffer/REG_4_reg i:/WORK/RequestBuffer/u_core/validPrev_reg\[2\]
rb_pin r:/WORK/RequestBuffer/REG_5_reg i:/WORK/RequestBuffer/u_core/timerClear_reg\[2\]
rb_pin r:/WORK/RequestBuffer/enable_REG_2_reg i:/WORK/RequestBuffer/u_core/histValidPrev_reg\[2\]
rb_pin r:/WORK/RequestBuffer/REG_6_reg i:/WORK/RequestBuffer/u_core/validPrev_reg\[3\]
rb_pin r:/WORK/RequestBuffer/REG_7_reg i:/WORK/RequestBuffer/u_core/timerClear_reg\[3\]
rb_pin r:/WORK/RequestBuffer/enable_REG_3_reg i:/WORK/RequestBuffer/u_core/histValidPrev_reg\[3\]
puts "RB_PIN_END ok=$::RB_PIN_OK bad=$::RB_PIN_BAD expect=$::RB_PIN_EXPECT"
if {$::RB_PIN_BAD != 0 || $::RB_PIN_OK != 12} {
  error "RB_PIN_MISMATCH ok=$::RB_PIN_OK bad=$::RB_PIN_BAD expect=$::RB_PIN_EXPECT"
}
}
