# ---------------------------------------------------------------------------
# ITTageTable —— MBIST 流水里「两侧对称死位」的双射钉点（只 set_user_match，
# 不放宽任何判据；属 fm_eq.tcl 的 FM_PIN_TCL 入口，在首次 match 之后执行）。
#
# 背景：本目标把 golden 的 MbistPipeIttage 重写成了 xs_MbistPipeIttage_core，
# 两侧寄存器叫法不同（golden firtool 名 vs 可读名）。绝大多数寄存器 Formality
# 靠签名分析自己配上了（去黑盒后 passing=10246 / unmatched=0），只剩 9 位
# **在两侧都读不到（cone-dead）**的地址位配不上——死位没有签名可比，名字词干
# 又不同（addrReg / addrRdReg  vs  addr_q / addr_rd_q），于是各自留在
# unmatched-unread 里。
#
# 为什么这 9 位在两侧都是死的：MBIST 写地址整条 8 位（addrReg）在
# FoldedSRAMTemplate_22 的 bore 口上没有被消费，读地址只用到 [6:0]
# （array_6_ext 的 RW0_addr 是 7 位），故 bit[7] 悬空。golden 与可读核**逐位
# 一一对应**，是同一组死位，不是任何一侧多出来的。
#
# 实测（2026-09-13，commit b2aba10 + 本 worktree 的 RTL_GOLDEN_DEPS 修复）：
#   fm_work/ITTageTable/unread_points.txt
#     ref : mbistPl/addrReg_reg[0..7]、mbistPl/addrRdReg_reg[7]        （9 个）
#     impl: mbistPl/addr_q_reg[0..7]、mbistPl/addr_rd_q_reg[7]         （9 个）
#   —— 9 对 9，双射唯一、无歧义。
#
# 钉上之后它们变成 matched-unread（matched_nc）。要把 unread 归零还需要
# verification_verify_matched_unread_compare_points=true（vmucp，**加强**：
# 要求 FM 真去比这些点，而不是当 Not-Compared 放过）。vmucp 在 scripts/fm_eq.tcl
# 里是精确白名单，ITTageTable 尚未在列——需要主集成者加名，本 worker 不碰
# scripts/。★本文件本身尚未在 FM 里跑过，待解冻后验证。★
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
  set _rp "r:/WORK/ITTageTable/mbistPl/$_r"
  set _ip "i:/WORK/ITTageTable/mbistPl/$_i"
  if {[catch {set_user_match $_rp $_ip} _msg]} {
    lappend _miss "$_rp <-> $_ip ($_msg)"
  } else {
    incr _n
  }
}
puts "ITTAGE_MBIST_DEADBIT_PIN: pinned $_n / 9"
foreach _m $_miss { puts "ITTAGE_MBIST_DEADBIT_PIN_FAIL: $_m" }
