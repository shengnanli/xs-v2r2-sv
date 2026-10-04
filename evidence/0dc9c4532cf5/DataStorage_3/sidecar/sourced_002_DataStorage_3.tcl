# vmucp 白名单条目：DataStorage_3
#
# 本文件 = DataStorage_3 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit f6806ac5 上的正式跑，vmucp 关）----
#   证据：evidence/f6806ac59aae/DataStorage_3（assembly，allow 精确相等：array_18_ext x4/侧 vendor_macro）
#   passing 1990 / failing 0 / unverified 0 / unmatched 0(0)，unread 544 -> 判 PARTIAL(assembly_unread!=0)。
#   与跑前登记（docs/lanes/l2slice_prereg.md 7.4 第二跑：unread 544 全 matched_nc）逐位相等。
#   544 个 unread 点全是 matched_nc（两侧独占 0），逐类：
#     r:REG_reg / REG_1_reg / REG_3_reg     <-> i:u_core/mcpEnPrev_reg / enPrev_reg / wrEnPrev_reg      （3）
#     r:REG_2_reg[b]                        <-> i:u_core/reqPrev_reg[b]      b in 0..13                   （14）
#     r:REG_4_reg[b]                        <-> i:u_core/wdataPrev_reg[b]    b in 0..511                  （512）
#     r:mbistPl/addrReg_reg[b]              <-> i:mbistPl/u_core/addrReg_reg[b]    b in 0..12             （13）
#     r:mbistPl/addrRdReg_reg[b]（1 位）    <-> i:mbistPl/u_core/addrRdReg_reg[b]                          （1）
#     r:mbistPl/beReg_reg                   <-> i:mbistPl/u_core/beReg_reg[0]                              （1）
#   为什么是对称死位：
#     前 529 位是 DataStorage.scala 三条 MCP2 保持性 assert 用到的 RegNext（golden 名 REG*），assert 在
#       ifndef SYNTHESIS 里，寄存器仍在网表里但没有读者；重写按 CONVENTIONS「debug 寄存器照写」保留。
#     后 15 位是 MBIST 叶子 L2DataStorage 的地址 / 字节选通寄存器：在 DataStorage 里它们送去的 SRAMTemplate
#       bore 口不用这些位（单口、无写掩码），父层语境下无读者；叶子单独签核时它们是被读的（evidence/6d68c540...）。
#   配对：REG* 与 beReg 由 verif/ut/DataStorage/fm_pins_pre.tcl 按名钉（530 位，fail-closed），其余 FM 按名自动配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 544 位。
#   (2) 双射：544 ref <-> 544 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 1990 -> 2534，正好 +544；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒集合与 allow 精确相等，无新黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 2534、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
