# DataStorage / DataStorage_1..3 FM「匹配前」钉点（手写；GatedSplittedSRAM* 不需要，直接跳过）
#
# 只消名差，不修错配：
#   (1) MCP2 断言影子寄存器：golden 叫 REG / REG_1 / REG_2 / REG_3 / REG_4（firtool 给 RegNext 起的匿名名），
#       重写核叫 mcpEnPrev / enPrev / reqPrev / wrEnPrev / wdataPrev（语义名）。它们只被 `ifndef SYNTHESIS
#       的 assert 读，是两侧对称的未读寄存器；FM 不给未读寄存器做签名配对，第一跑（evidence/2690db30...）
#       里 526 位两侧各自落单、另有 2 位被错配到 wdataPrev —— 所以必须按名钉。
#   (2) mbistPl（L2DataStorage*）的 1 位 beReg：golden 是标量 beReg_reg，重写核按参数写成 [BE_W-1:0]，
#       FM 名是 beReg_reg[0]。在 DataStorage 里它没有读者（SRAM 无写掩码），同样落单。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面 530（1+1+14+1+512+1）就 error。进 fm.log 的输出一律 ASCII。
if {[string match {DataStorage*} $top]} {
  set ::DS_PIN_EXPECT 530
  set ::DS_PIN_OK 0
  set ::DS_PIN_BAD 0
  proc ds_pin {r i} {
    if {[set_user_match $r $i]} { incr ::DS_PIN_OK } else {
      incr ::DS_PIN_BAD
      if {$::DS_PIN_BAD <= 10} { puts "DS_PIN_FAIL: $r <-> $i" }
    }
  }
  puts "DS_PIN_BEGIN $top expect=$::DS_PIN_EXPECT"
  ds_pin "r:/WORK/$top/REG_reg"   "i:/WORK/$top/u_core/mcpEnPrev_reg"
  ds_pin "r:/WORK/$top/REG_1_reg" "i:/WORK/$top/u_core/enPrev_reg"
  ds_pin "r:/WORK/$top/REG_3_reg" "i:/WORK/$top/u_core/wrEnPrev_reg"
  for {set b 0} {$b < 14} {incr b} {
    ds_pin "r:/WORK/$top/REG_2_reg\[$b\]" "i:/WORK/$top/u_core/reqPrev_reg\[$b\]"
  }
  for {set b 0} {$b < 512} {incr b} {
    ds_pin "r:/WORK/$top/REG_4_reg\[$b\]" "i:/WORK/$top/u_core/wdataPrev_reg\[$b\]"
  }
  ds_pin "r:/WORK/$top/mbistPl/beReg_reg" "i:/WORK/$top/mbistPl/u_core/beReg_reg\[0\]"
  puts "DS_PIN_END $top ok=$::DS_PIN_OK bad=$::DS_PIN_BAD"
  if {$::DS_PIN_BAD != 0 || $::DS_PIN_OK != 530} {
    error "DS_PIN_MISMATCH ok=$::DS_PIN_OK bad=$::DS_PIN_BAD expect=$::DS_PIN_EXPECT"
  }
}
