# GPAMem FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：子模块 SyncDataModuleTemplate__64entry_5（4 bank × 16 项）里 12 个**对称死位**：
#   (a) 每个 bank 自己那份读地址副本 raddr_dup_0_<b>[5:4]（bank 内只用低 4 位选项，
#       高 2 位是 bank 号、bank 内无读者）：golden mem/raddr_dup_0{,_1,_2,_3}_reg[5:4]
#       ↔ 可读核 mem/u_core/g_bank[b].raddr_dup_reg[0][5:4]      —— 8 位
#   (b) 输出级那份读地址副本的低 4 位 raddr_dup[3:0]（输出级只用高 2 位选 bank）：
#       golden mem/raddr_dup_reg[3:0] ↔ 可读核 mem/u_core/g_rport[0].raddr_q_reg[3:0] —— 4 位
# 首跑（evidence/9154088d8da0/GPAMem）：native SUCCEEDED、passing 3983、failing 0、
# unmatched compare points 0(0)，只剩这 12 点 unmatched-unread（ref 12 / impl 12）。
# 两侧死因相同（同一分 bank 结构下同一批高/低位无读者），按结构一一对应，这里显式钉死，
# 再由 vmucp 把它们当比较点真比（见 verif/fm_target_config/GPAMem.tcl）。
#
# fail-closed：set_user_match 从不抛异常，用返回值判；钉完再数，必须正好 12，否则 error 中止
# （本文件跑在 sidecar 的 safe interp 里，那里没有 exit）。
set _gpa_expect 12
set _gpa_n 0
set _gpa_fail 0
puts "GPAMEM_PIN_BEGIN $top expect=$_gpa_expect"
foreach _pair {
  {mem/raddr_dup_0_reg\[4\]   mem/u_core/g_bank\[0\].raddr_dup_reg\[0\]\[4\]}
  {mem/raddr_dup_0_reg\[5\]   mem/u_core/g_bank\[0\].raddr_dup_reg\[0\]\[5\]}
  {mem/raddr_dup_0_1_reg\[4\] mem/u_core/g_bank\[1\].raddr_dup_reg\[0\]\[4\]}
  {mem/raddr_dup_0_1_reg\[5\] mem/u_core/g_bank\[1\].raddr_dup_reg\[0\]\[5\]}
  {mem/raddr_dup_0_2_reg\[4\] mem/u_core/g_bank\[2\].raddr_dup_reg\[0\]\[4\]}
  {mem/raddr_dup_0_2_reg\[5\] mem/u_core/g_bank\[2\].raddr_dup_reg\[0\]\[5\]}
  {mem/raddr_dup_0_3_reg\[4\] mem/u_core/g_bank\[3\].raddr_dup_reg\[0\]\[4\]}
  {mem/raddr_dup_0_3_reg\[5\] mem/u_core/g_bank\[3\].raddr_dup_reg\[0\]\[5\]}
  {mem/raddr_dup_reg\[0\]     mem/u_core/g_rport\[0\].raddr_q_reg\[0\]}
  {mem/raddr_dup_reg\[1\]     mem/u_core/g_rport\[0\].raddr_q_reg\[1\]}
  {mem/raddr_dup_reg\[2\]     mem/u_core/g_rport\[0\].raddr_q_reg\[2\]}
  {mem/raddr_dup_reg\[3\]     mem/u_core/g_rport\[0\].raddr_q_reg\[3\]}
} {
  lassign $_pair _r _i
  if {[set_user_match "r:/WORK/$top/$_r" "i:/WORK/$top/u_core/$_i"]} {
    incr _gpa_n
  } else {
    puts "GPAMEM_PIN_FAIL: $_r <-> $_i"
    incr _gpa_fail
  }
}
puts "GPAMEM_PIN_END $top n=$_gpa_n fail=$_gpa_fail expect=$_gpa_expect"
if {$_gpa_fail != 0 || $_gpa_n != $_gpa_expect} {
  puts "GPAMEM_PIN_ERROR: pinned $_gpa_n (fail $_gpa_fail) but expected $_gpa_expect"
  error "GPAMEM_PIN_COUNT=$_gpa_n"
}
match
