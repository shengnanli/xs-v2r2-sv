# Directory（slice 0）FM「匹配前」钉点（手写；Directory_1..3 与 SplittedSRAM_* 不需要，直接跳过）
#
# 只消名差：slice 0 的 MBIST 叶子 L2Directory 用的是更早签核的手写件 rtl/uncore/L2Directory.sv，
# 它把输入寄存级包在子模块 u_ctrl 里（xs_mbist_pipe_ctrl），于是寄存器路径比 golden 多一层：
#   golden  mbistPl/addrReg_reg[b]            <-> 重写 mbistPl/u_core/u_ctrl/addrReg_reg[b]     b=0..9
#   golden  mbistPl/addrRdReg_reg[9]          <-> 重写 mbistPl/u_core/u_ctrl/addrRdReg_reg[9]
# 这 11 位在 Directory 里没有读者（tag/meta/repl/orgb 四类 SRAM 的 bore 口不用这些地址位），两侧对称未读；
# FM 不给未读寄存器做签名配对，第一跑（evidence/2690db305435/Directory）里它们两侧各自落单。
# Directory_1..3 的 MBIST 叶子走 xs_mbist_pipe_core（无 u_ctrl 层），FM 按名自动配上，不用钉。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面 11 就 error。进 fm.log 的输出一律 ASCII。
if {$top eq "Directory"} {
  set ::DIR_PIN_EXPECT 11
  set ::DIR_PIN_OK 0
  set ::DIR_PIN_BAD 0
  proc dir_pin {r i} {
    if {[set_user_match $r $i]} { incr ::DIR_PIN_OK } else {
      incr ::DIR_PIN_BAD
      if {$::DIR_PIN_BAD <= 10} { puts "DIR_PIN_FAIL: $r <-> $i" }
    }
  }
  puts "DIR_PIN_BEGIN $top expect=$::DIR_PIN_EXPECT"
  for {set b 0} {$b < 10} {incr b} {
    dir_pin "r:/WORK/$top/mbistPl/addrReg_reg\[$b\]" "i:/WORK/$top/mbistPl/u_core/u_ctrl/addrReg_reg\[$b\]"
  }
  dir_pin "r:/WORK/$top/mbistPl/addrRdReg_reg\[9\]" "i:/WORK/$top/mbistPl/u_core/u_ctrl/addrRdReg_reg\[9\]"
  puts "DIR_PIN_END $top ok=$::DIR_PIN_OK bad=$::DIR_PIN_BAD"
  if {$::DIR_PIN_BAD != 0 || $::DIR_PIN_OK != 11} {
    error "DIR_PIN_MISMATCH ok=$::DIR_PIN_OK bad=$::DIR_PIN_BAD expect=$::DIR_PIN_EXPECT"
  }
}
