# IBuffer FM 匹配后钉点 —— 1 族结构双射，共 6 个点
# ============================================================================
# 【本文件解决什么】
#   IBuffer 的 signoff-strict 首跑（commit 4fefc6a，未钉点）：
#       native SUCCEEDED / passing 7902 / failing 0 / unverified 0 / aborted 0 /
#       unmatched compare points 0(0) / 黑盒 0 / 无 dont_verify / 无 ELAB 抑制
#   只剩一行拦着：
#       6(6) Unmatched reference(implementation) unread points
#   即 fm_verdict.py 的 strict_unread!=0 → PARTIAL。
#
#   这 6(6) 点是 golden 的 deqInBankPtr 的 6 个 flag 寄存器：
#       ref   r:/WORK/IBuffer/deqInBankPtr_<b>_flag_reg              b = 0..5
#       impl  i:/WORK/IBuffer/u_core/deq_inbank_flag_q_reg[<b>]      b = 0..5
#   两侧各 6 个、非 matched_nc 项为 0，干净的 6↔6。名字配不上只有两个原因：
#   叶名词干不同（deqInBankPtr_0_flag vs deq_inbank_flag_q[0]）、impl 侧多一层
#   u_core。**结构上没有自由度**：下标就是 bank 号，0↔0 … 5↔5。
#
# ============================================================================
# 【为什么这 6 个点两侧都是死位 —— 同一个死因，不是"impl 侧超配"】
#   IBufInBankPtr 是 CircularQueuePtr(entries = IBufSize/IBufNBank = 8)。8 是 2 的幂，
#   {flag,value}+1 的进位天然落进 flag。但 flag **唯一的读出点就是它自己的次态**：
#     golden IBuffer.sv:9080   _deqInBankPtrNext_0_new_ptr_T_1
#                                = 4'({deqInBankPtr_0_flag, deqInBankPtr_0_value} + 4'h1)
#     golden IBuffer.sv:21384  deqInBankPtr_0_flag <= ~io_flush
#                                & (bankAdvance ? _deqInBankPtrNext_0_new_ptr_T_1[3]
#                                               : deqInBankPtr_0_flag)
#   全文再无第三处引用。可读核 §7/§9 是同一形状：
#     inbank_inc[b] = {deq_inbank_flag_q[b], deq_inbank_value_q[b]} + 1
#     deq_inbank_flag_q[b] <= ~flush & (bank_advance[b] ? inbank_inc[b][INBANK_W]
#                                                       : deq_inbank_flag_q[b])
#   ★两侧同为自环死寄存器，次态函数逐字同构★。对比：同一模块里 deqBankPtrVec 的
#   flag 被 firtool 整片消掉（6 value / 0 flag），deqInBankPtr 的却留着 —— 可读核
#   照 golden 保留了这 6 个，所以才有对家可钉；若按 Chisel 字面"每个指针都有 flag"
#   写，deqBankPtrVec 那边会凭空多 6 个**没有对家**的寄存器，那是钉不掉的。
#
# 【只做一件事】
#   只 set_user_match 消名差。不 dont_verify、不放宽 appvar、不约束 ref、不扩黑盒。
#   钉点只让 FM 少猜，不让它少证：钉上之后这 6 点从"未配未读"变成"已配未读"，
#   再配合 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 这个**加强**开关，FM 才
#   真去证它们。判据是 passing 必须 7902 -> 7908（恰好 +6）、failing 仍 0、
#   unread 归 0 —— ★passing 不增就是空转，不算过★。
#   钉错的后果是 FM 判不等价（响亮失败），不是静默放过，方向上是安全的。
#
# ============================================================================
# 【★沙箱实测更正：safe interp 里没有 find_cells，但有 report_*_points★】
#   scripts/sidecar/fm_native_emit.tcl 的 sidecar_pin_source 用 `interp create -safe`
#   建 child interp，白名单 alias 是：
#       set_user_match set_app_var get_app_var puts
#       report_unmatched_points report_matched_points set_constant remove_constant
#       setup set_dont_verify_points set_compare_rule match verify
#   **find_cells 不在其中**。本文件第一版照 wt-predictor 的 fm_pins_pre.tcl 写成
#   `if {[info commands find_cells] eq ""} {error ...}`，实测当场 fail-closed 退出
#   （fm.log:533 Error: IBUFFER_PIN: 只读查询动词 'find_cells' 不可用）。
#
#   改用白名单里本来就有的 report_unmatched_points 做 discover —— 对本目标反而更好：
#   它枚举的**正是**"当前还没配上的未读点"这个集合本身，而不是先假设名字形状再去
#   查存在性。于是"钉哪些点"是**查出来的**，"怎么配对"是**结构定的**（bank 下标），
#   两者都没有手写名单。fm_eq.tcl 自己在 545-553 行写 unread_points.txt 用的也是
#   同一个动词，口径一致、可复算。
#
# 【fail-closed】
#   下面每一步不满足就 error 退出，绝不降级成"照名字硬猜"或"能钉几个算几个"：
#     · 查询动词缺失
#     · 任一侧未读点数 != 6
#     · 任一条路径不符合本族的形状正则（出现第 7 个/别的族的点立刻炸）
#     · 两侧 bank 下标集合不相等（不是 {0,1,2,3,4,5}）
#     · set_user_match 有任何一条失败
# ============================================================================

if {$top eq "IBuffer"} {

  # --- 0) 查询动词可用性 -----------------------------------------------------
  if {[info commands report_unmatched_points] eq ""} {
    error "IBUFFER_PIN: 只读查询动词 'report_unmatched_points' 不可用 —— 无法 discover，拒绝硬猜名字"
  }

  set _expect 6   ;# IBufNBank = 6（golden readStage1_0 取 ibuf_{0,6,...,42}，步长 6 实测）

  # --- 1) discover：两侧当前未配的未读点 -------------------------------------
  set _rawref [lsort -unique [report_unmatched_points -reference      -status unread -list]]
  set _rawimp [lsort -unique [report_unmatched_points -implementation -status unread -list]]

  # --- 2) 形状校验 + 按 bank 下标建表（任何不合形状的点直接炸）--------------
  set _reRef "^r:/WORK/$top/deqInBankPtr_(\[0-9\]+)_flag_reg\$"
  set _reImp "^i:/WORK/$top/u_core/deq_inbank_flag_q_reg\\\[(\[0-9\]+)\\\]\$"
  array set _R {}
  array set _I {}
  set _oddref {}
  set _oddimp {}
  foreach _p $_rawref {
    if {[regexp $_reRef $_p _all _b]} { set _R($_b) $_p } else { lappend _oddref $_p }
  }
  foreach _p $_rawimp {
    if {[regexp $_reImp $_p _all _b]} { set _I($_b) $_p } else { lappend _oddimp $_p }
  }

  set _bad 0
  if {[llength $_oddref] != 0} {
    puts "IBUFFER_PIN_FAIL(golden侧出现本族之外的未读点): [llength $_oddref] 个"
    foreach _x $_oddref { puts "    $_x" }
    incr _bad
  }
  if {[llength $_oddimp] != 0} {
    puts "IBUFFER_PIN_FAIL(可读核侧出现本族之外的未读点): [llength $_oddimp] 个"
    foreach _x $_oddimp { puts "    $_x" }
    incr _bad
  }
  if {[array size _R] != $_expect} {
    puts "IBUFFER_PIN_AUDIT: golden 侧本族未读点 [array size _R] 个，应为 $_expect"
    incr _bad
  }
  if {[array size _I] != $_expect} {
    puts "IBUFFER_PIN_AUDIT: 可读核侧本族未读点 [array size _I] 个，应为 $_expect"
    incr _bad
  }
  # 下标集合必须严格相等，且正好是 0..5（不是"碰巧数目一样"）
  set _kr [lsort -integer [array names _R]]
  set _ki [lsort -integer [array names _I]]
  set _kx {}
  for {set b 0} {$b < $_expect} {incr b} { lappend _kx $b }
  if {$_kr ne $_kx || $_ki ne $_kx} {
    puts "IBUFFER_PIN_AUDIT: bank 下标集合不符 —— golden={$_kr} 可读核={$_ki} 应为 {$_kx}"
    incr _bad
  }
  if {$_bad != 0} {
    error "IBUFFER_PIN_SHAPE: 未读点集合与本族声明不符，拒绝钉点（bad=$_bad）"
  }

  # --- 3) 逐对钉点：下标同号，没有自由度 -------------------------------------
  set _n 0
  set _fail {}
  for {set b 0} {$b < $_expect} {incr b} {
    if {[catch {set_user_match $_R($b) $_I($b)} _m]} {
      lappend _fail "bank $b : $_R($b) <-> $_I($b) : $_m"
    } else {
      incr _n
      puts "IBUFFER_PIN: $_R($b) <-> $_I($b)"
    }
  }
  if {[llength $_fail] != 0} {
    puts "IBUFFER_PIN_FAIL(钉点失败): [llength $_fail] 个"
    foreach _x $_fail { puts "    $_x" }
  }

  puts "IBUFFER_PINS: $_n / $_expect pinned"
  if {$_n != $_expect || [llength $_fail] != 0} {
    error "IBUFFER_PIN_MISS: n=$_n expect=$_expect fail=[llength $_fail]"
  }
}
