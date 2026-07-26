# RXSNP 匹配后钉点(FM_PIN_TCL): 对称死寄存器 bijection 的显式一一对应。
#
# 背景: signoff-strict 下 verification_verify_unread_compare_points=false ⇒ 完全 cone-dead
# 的寄存器落入 "Not Compared / Unread"。RXSNP 有 68 个这样的**对称死** DFF, 全部
# ref==impl 一一对应(去掉 impl 侧 u_core/ 层次前缀后同名), 是名副其实的双射:
#
#   (a) stallCnt_reg[0..63]  (64 个)
#       —— 死锁监视计数器, 仅在 `ifndef SYNTHESIS 的 $fwrite 断言里被读;
#          FM 用 -define {SYNTHESIS} 编译两侧, 断言被裁剪 ⇒ stallCnt 无观测扇出 (cone-dead)。
#          ref: RXSNP/stallCnt_reg[b]  ↔  impl: RXSNP/u_core/stallCnt_reg[b]
#
#   (b) queue/ram_ext/Memory_reg[{0,1}][{54,55}]  (4 个)
#       —— 白盒 golden Queue2_CHISNP 内 98bit RAM 字里对应 addr[4:3] 的 2 位。
#          RXSNP 组装 task 时 off={addr[2:0],3'h0}、set=addr[13:5], addr[4:3] 从不被读 ⇒
#          该 2 位在整个 RXSNP cone 内死。两侧例化同一 golden 子模块 ⇒ 天然对称。
#          ref: RXSNP/queue/ram_ext/Memory_reg[w][b] ↔ impl: RXSNP/u_core/queue/ram_ext/Memory_reg[w][b]
#
# 这些点在 auto-match 阶段已按名配上(见 unmatched.rpt="No unmatched points"), 本文件把
# 双射**显式钉死**以防命名漂移, 并配合 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM
# **真正比较**它们(证明 ref==impl, 非 waiver)。加强后 68 个从 Unread 转为 Passing。

set _n 0

# (a) stallCnt 64 位
for {set b 0} {$b < 64} {incr b} {
  set r "r:/WORK/RXSNP/stallCnt_reg\[$b\]"
  set i "i:/WORK/RXSNP/u_core/stallCnt_reg\[$b\]"
  if {![catch {set_user_match $r $i}]} { incr _n }
}

# (b) Queue2_CHISNP RAM 内 addr[4:3] 死位: word 0/1, bit 54/55
foreach w {0 1} {
  foreach b {54 55} {
    set r "r:/WORK/RXSNP/queue/ram_ext/Memory_reg\[$w\]\[$b\]"
    set i "i:/WORK/RXSNP/u_core/queue/ram_ext/Memory_reg\[$w\]\[$b\]"
    if {![catch {set_user_match $r $i}]} { incr _n }
  }
}

puts "RXSNP_SYMDEAD_PINS: $_n points pinned (expect 68)"
