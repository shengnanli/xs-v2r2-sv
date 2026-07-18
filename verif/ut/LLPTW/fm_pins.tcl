# LLPTW FM 钉点: golden 两个 addr_check 打拍寄存器名字相近, 签名分析把
#   hptw_need_addr_check_REG_reg(hptw 路, 无复位) 错配到 impl need_addr_check_reg(in_fire 路, 有复位),
# 留下 need_addr_check_last_REG_reg(ref) 与 hptw_need_addr_check_q_reg(impl) 无对。
# 先撤销错配, 再按语义一一钉死。
catch {undo_match "r:/WORK/$top/hptw_need_addr_check_REG_reg"}
catch {undo_match "i:/WORK/$top/u_core/need_addr_check_reg"}
foreach {rl il} {
  need_addr_check_last_REG_reg  u_core/need_addr_check_reg
  hptw_need_addr_check_REG_reg  u_core/hptw_need_addr_check_q_reg
} {
  if {[catch {set_user_match "r:/WORK/$top/$rl" "i:/WORK/$top/$il"} msg]} {
    puts "PIN_FAIL: $rl <-> $il ($msg)"
  } else {
    puts "PIN_OK: $rl <-> $il"
  }
}
puts "LLPTW_PINS: done"
