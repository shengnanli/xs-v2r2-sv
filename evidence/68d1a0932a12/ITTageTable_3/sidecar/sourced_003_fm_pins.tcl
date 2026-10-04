# ---------------------------------------------------------------------------
# ITTageTable_3 —— MBIST 流水里「两侧对称死位」的双射钉点（只 set_user_match，
# 不放宽任何判据）。属 fm_eq.tcl 的 FM_PIN_TCL 入口，在首次 match 之后执行。
# 与 verif/ut/ITTageTable/fm_pins.tcl 同源同依据，只是顶层名与 MBIST 流水变体
# 不同（本变体 golden 侧流水 = MbistPipeIttage_3，SRAM bank 数 = 2）。
#
# 背景：本目标把 golden 的 MbistPipeIttage_3 重写成了 xs_MbistPipeIttage_core，
# 两侧寄存器叫法不同（golden firtool 名 vs 可读名）。绝大多数寄存器 Formality
# 靠签名分析自己配上了（去黑盒后 unmatched=0），只剩 9 位**在两侧都读不到
# （cone-dead）**的 MBIST 地址位配不上——死位没有签名可比，名字词干又不同
# （addrReg / addrRdReg  vs  addr_q / addr_rd_q），于是各自留在 unread 的
# unmatched 里（ref 9 / impl 9）。
#
# 为什么这 9 位在两侧都是死的（2026-09-14 逐文件复核，非沿用旧结论）：
#   golden MbistPipeIttage*.sv:195-196
#     toSRAM_0_addr    = doSpread ? addrReg    : 8'h0   （写地址，8 位）
#     toSRAM_0_addr_rd = doSpread ? addrRdReg  : 8'h0   （读地址，8 位）
#   两者一路直连到 SRAMTemplate_7{6,8}.sv:123-124
#     wire [7:0] mbistBd_addr    = boreChildrenBd_bore_addr;
#     wire [7:0] mbistBd_addr_rd = boreChildrenBd_bore_addr_rd;
#   其中 **mbistBd_addr 全 8 位在整个文件里再无第二处引用**（只有第 123 行的
#   定义），而 mbistBd_addr_rd 只在第 215 行以 mbistBd_addr_rd[6:0] 被消费
#   ——因为最终的厂商 SRAM 宏 array_6_ext.v 的 RW0_addr 只有 7 位（深度 128）。
#   故死位 = addrReg[7:0]（8 位，写地址整条）+ addrRdReg[7]（1 位）= 9 位。
#   golden 与可读核逐位一一对应，是同一组死位，不是任何一侧多出来的。
#
# 另有 2 个 array_6_ext/reg_RW0_ren_reg 也是 unread，但它们**两侧同名同路径**
# （同一份 golden 厂商宏在两侧一起 elaborate），Formality 自己就配上了
# （matched_nc），不需要钉。它们死的原因见 array_6_ext.v:40-43：
# reg_RW0_ren 只在 `ifdef RANDOMIZE_GARBAGE_ASSIGN 分支里被读，综合视图下
# 走的是 `else 分支 assign RW0_rdata = ram[reg_RW0_addr]，该寄存器无读者。
#
# 钉上之后这 9 对变成 matched-unread（matched_nc）。要把 unread 归零还需要
# verification_verify_matched_unread_compare_points=true（vmucp，**加强**：
# 要求 FM 真去比这些点，而不是当 Not-Compared 放过），本 UT 的 Makefile 已
# 声明该变量，白名单见 scripts/fm_eq.tcl。
#
# 失败处理：用 catch 逐对钉、末尾打印计数。钉不上只会让该点继续留在 unread、
# 判定继续 PARTIAL（fail-closed 方向），不可能造成假绿。
# ---------------------------------------------------------------------------
set _n 0
set _miss {}
foreach {_r _i} {
  addrReg_reg[0]   addr_q_reg[0]
  addrReg_reg[1]   addr_q_reg[1]
  addrReg_reg[2]   addr_q_reg[2]
  addrReg_reg[3]   addr_q_reg[3]
  addrReg_reg[4]   addr_q_reg[4]
  addrReg_reg[5]   addr_q_reg[5]
  addrReg_reg[6]   addr_q_reg[6]
  addrReg_reg[7]   addr_q_reg[7]
  addrRdReg_reg[7] addr_rd_q_reg[7]
} {
  set _rp "r:/WORK/ITTageTable_3/mbistPl/$_r"
  set _ip "i:/WORK/ITTageTable_3/mbistPl/$_i"
  if {[catch {set_user_match $_rp $_ip} _msg]} {
    lappend _miss "$_rp <-> $_ip ($_msg)"
  } else {
    incr _n
  }
}
puts "ITTAGE_MBIST_DEADBIT_PIN: pinned $_n / 9"
foreach _m $_miss { puts "ITTAGE_MBIST_DEADBIT_PIN_FAIL: $_m" }
