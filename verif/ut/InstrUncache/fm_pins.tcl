# InstrUncache FM 钉点（2026-09-14，PARTIAL 收口簇）——条目锁存地址的死最低位
# ============================================================================
# 症状：signoff-strict 下 native SUCCEEDED / passing 204 / failing 0 /
#       unmatched compare points 0，唯独剩 1(1) unmatched **unread**：
#         Ref   r:/WORK/InstrUncache/entries_0/req_addr_reg[0]
#         Impl  i:/WORK/InstrUncache/entries_0/u_core/req_reg\[addr][0]
#       于是 verdict 卡在 strict_unread!=0。
#
# 这一位是什么：InstrMMIOEntry 锁存 IFU 请求地址（golden InstrMMIOEntry.sv:112
#   `reg [47:0] req_addr;`，154 行 `req_addr <= io_req_bits_addr;`）。锁存之后
#   只有两个读者：
#     InstrMMIOEntry.sv:193  io_resp_bits_data = _GEN_1[req_addr[2:1]]  （选 16 位半字）
#     InstrMMIOEntry.sv:196  io_mmio_acquire_bits_address = {req_addr[47:3], 3'h0}
#   —— MMIO 取指按 8 字节对齐发 Get、按半字选指令，**bit 0 永远没有读者**。
#   可读核照抄同一行为（rtl/frontend/InstrMMIOEntry.sv 的 latched_req_t.addr），
#   所以两侧同为死位，1↔1 严格双射，非本点的未读项为 0。
#
# 为什么 FM 自己配不上：活位 [47:1] 有输出锥，签名分析已经配好了（都在 204 个
#   passing 里）；死位没有输出锥，只能靠名字，而两侧词干不同——
#     golden 逐字段展平  req_addr_reg[0]
#     可读核 packed struct 展平  req_reg\[addr][0]
#   （与 ICacheCtrlUnit 的 ram_reg ↔ slot_reg\[data] 同型。）
#
# 本钉点只消名差：不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点。
# 钉上之后该点变成 matched-unread；要让 strict 的 unread 归零还需要 target-scoped
# 的 verification_verify_matched_unread_compare_points=true（白名单在
# scripts/fm_eq.tcl，本 UT 的 Makefile 同步打开），届时 FM 会**真去比这一位**，
# passing 应由 204 增至 205。
#
# 本文件被同目录三个变体共用（FM_VARIANTS = InstrMMIOEntry
# Arbiter1_InsUncacheResp InstrUncache）。只对 InstrUncache 生效：其余两个 top
# 下该路径不存在，显式用 $top 门控，避免"钉不上也不报"的静默。
# ============================================================================

if {$top eq "InstrUncache"} {
  if {[catch {set_user_match "r:/WORK/$top/entries_0/req_addr_reg\[0\]" \
                             "i:/WORK/$top/entries_0/u_core/req_reg\\\[addr\]\[0\]"} _msg]} {
    puts "INSTRUNCACHE_PINS_FAIL: entries_0 req_addr\[0\] -> $_msg"
  } else {
    puts "INSTRUNCACHE_PINS: entries_0 dead req_addr\[0\] 1 / 1 point pinned"
  }
}
