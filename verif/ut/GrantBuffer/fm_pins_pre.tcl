# GrantBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_grantbuf.py（勿手改）
#
# 钉 33 个两侧都没有读者、名字又不同的寄存器位：
# (1) perf 专用的 32 个 1 位寄存器（每个 inflight 项 2 个 RegNext(valid)）：
#   golden  REG[_k] / enable_REG[_k]   <->  重写  u_core/validPrev / histValidPrev [k]
# REG 只喂 perf 计时器 timers（计时器只被 ifndef SYNTHESIS 的 assert 读），enable_REG 谁也不读：
# (2) grantBuf 暂存的 param[2]：golden grantBuf_task_param[2] <-> 重写 u_core/gb_param[2]；
#     D 通道 param 只有 2 位，两侧都只读 [1:0]。
# 两侧对称的未读寄存器，FM 不给未读寄存器做签名配对，名字又不同，不钉就两侧各自落单。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面位数就 error。进 fm.log 的输出一律 ASCII。
# 本目录还有 Queue10_GrantBuffer_Anon 一个 FM 目标：钉点只对 top 为 GrantBuffer 时生效。
if {$top eq "GrantBuffer"} {
set ::GB_PIN_EXPECT 33
set ::GB_PIN_OK 0
set ::GB_PIN_BAD 0
proc gb_pin {r i} {
  if {[set_user_match $r $i]} { incr ::GB_PIN_OK } else {
    incr ::GB_PIN_BAD
    if {$::GB_PIN_BAD <= 10} { puts "GB_PIN_FAIL: $r <-> $i" }
  }
}
puts "GB_PIN_BEGIN GrantBuffer expect=$::GB_PIN_EXPECT"
gb_pin r:/WORK/GrantBuffer/REG_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[0\]
gb_pin r:/WORK/GrantBuffer/enable_REG_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[0\]
gb_pin r:/WORK/GrantBuffer/REG_1_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[1\]
gb_pin r:/WORK/GrantBuffer/enable_REG_1_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[1\]
gb_pin r:/WORK/GrantBuffer/REG_2_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[2\]
gb_pin r:/WORK/GrantBuffer/enable_REG_2_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[2\]
gb_pin r:/WORK/GrantBuffer/REG_3_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[3\]
gb_pin r:/WORK/GrantBuffer/enable_REG_3_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[3\]
gb_pin r:/WORK/GrantBuffer/REG_4_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[4\]
gb_pin r:/WORK/GrantBuffer/enable_REG_4_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[4\]
gb_pin r:/WORK/GrantBuffer/REG_5_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[5\]
gb_pin r:/WORK/GrantBuffer/enable_REG_5_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[5\]
gb_pin r:/WORK/GrantBuffer/REG_6_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[6\]
gb_pin r:/WORK/GrantBuffer/enable_REG_6_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[6\]
gb_pin r:/WORK/GrantBuffer/REG_7_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[7\]
gb_pin r:/WORK/GrantBuffer/enable_REG_7_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[7\]
gb_pin r:/WORK/GrantBuffer/REG_8_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[8\]
gb_pin r:/WORK/GrantBuffer/enable_REG_8_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[8\]
gb_pin r:/WORK/GrantBuffer/REG_9_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[9\]
gb_pin r:/WORK/GrantBuffer/enable_REG_9_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[9\]
gb_pin r:/WORK/GrantBuffer/REG_10_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[10\]
gb_pin r:/WORK/GrantBuffer/enable_REG_10_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[10\]
gb_pin r:/WORK/GrantBuffer/REG_11_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[11\]
gb_pin r:/WORK/GrantBuffer/enable_REG_11_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[11\]
gb_pin r:/WORK/GrantBuffer/REG_12_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[12\]
gb_pin r:/WORK/GrantBuffer/enable_REG_12_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[12\]
gb_pin r:/WORK/GrantBuffer/REG_13_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[13\]
gb_pin r:/WORK/GrantBuffer/enable_REG_13_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[13\]
gb_pin r:/WORK/GrantBuffer/REG_14_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[14\]
gb_pin r:/WORK/GrantBuffer/enable_REG_14_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[14\]
gb_pin r:/WORK/GrantBuffer/REG_15_reg i:/WORK/GrantBuffer/u_core/validPrev_reg\[15\]
gb_pin r:/WORK/GrantBuffer/enable_REG_15_reg i:/WORK/GrantBuffer/u_core/histValidPrev_reg\[15\]
gb_pin r:/WORK/GrantBuffer/grantBuf_task_param_reg\[2\] i:/WORK/GrantBuffer/u_core/gb_param_reg\[2\]
puts "GB_PIN_END ok=$::GB_PIN_OK bad=$::GB_PIN_BAD expect=$::GB_PIN_EXPECT"
if {$::GB_PIN_BAD != 0 || $::GB_PIN_OK != 33} {
  error "GB_PIN_MISMATCH ok=$::GB_PIN_OK bad=$::GB_PIN_BAD expect=$::GB_PIN_EXPECT"
}
}
