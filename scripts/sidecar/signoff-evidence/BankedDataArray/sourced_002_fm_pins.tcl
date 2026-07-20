# BankedDataArray FM 钉点（FM 审计 2026-07）
# SRAM 宏（array_ext 等）黑盒两侧例化；部分引脚（如未用的 mbist/写口分身）两侧悬空。
# FM 默认 verification_set_undriven_signals=BINARY:X（ref 悬空=自由割点、impl 悬空=X），
# 凡锥含悬空信号必失配。设 BINARY 让两侧悬空信号按同名配对为同一自由变量。
setup

# FM 的寄存器初值推断（Auto）会把一侧部分寄存器约束成常量（两侧不对称 → 锥失配），关掉。
if {[catch {set_app_var verification_assume_reg_init none} msg]} { puts "PINS: assume_reg_init failed: $msg" }
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} { puts "PINS: undriven failed: $msg" }
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} {
  puts "BDA_PINS: set_app_var failed: $msg"
}
puts "BDA_PINS: applied"
