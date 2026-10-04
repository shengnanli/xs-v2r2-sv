# vmucp 白名单条目：VTypeBuffer（2026-10-03，agent/rob-regcache，本 lane 实测）
#
# ---- 基线（诊断跑，diagnostic-full，vmucp=false，FM_MERGE_DUP=false，verif/ut/VTypeBuffer，未钉点）----
#   native SUCCEEDED / passing 1297 / failing 0 / constant_reg 9（commitSize/walkSize/spclWalkSize[6:4]）/
#   unread：matched_nc 64（deqPtrOH_reg[0..63]，两侧同名）+ unmatched unread ref 150 / impl 150。
#   1297 + 9 + 64 + 150 = 1520 = regs 1496 + outs 24（fm_predict 模型），逐项指认。
#
# 这些位是什么（两侧对称的无读者寄存器，golden 自带，重写按 Scala 结构照留）：
#   · deqPtrOH（64）：deqPtr 的独热副本，Scala 只用于 XSError 自检，综合后无读者；
#   · deqPtrVec_1..7（49）：dontTouch(deqPtrVec) 留下，读者只有 deqPtrVec_0；
#   · enqPtrVec_1..5 的 flag（5）：写地址只用 value；
#   · 子模块 SyncDataModuleTemplate__64entry_4 里读地址寄存器的半边（96）：bank 内地址副本只用 [3:0]、
#     读口 bank 选择只用 [5:4]。
#   150 个 unmatched 由 verif/ut/VTypeBuffer/fm_pins.tcl 逐位钉成双射（字面计数 150，fail-closed）。
#
# ---- standing rule 六条 ----
# 1 精确绑定：64 对按名、150 对按 fm_pins.tcl 逐位钉（路径由 golden/重写件结构机械推出，见该文件头）。
# 2 双射：同一下标同一位，k<->k；150 与 64 两组互不重叠。
# 3 passing 正好增 unread 数：1297 -> 1511（+214 = 64 + 150）（official 复核判据）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无黑盒（子模块两侧白盒）。
# 6 摘要：本文件 + docs/lanes/rob-regcache_prereg.md §B.4。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 214 位（变异 M22 —— deqPtrOH 去掉循环回绕 —— UT 不可观测，
#   靠的就是这里把 deqPtrOH 纳入比较）。

fm_target_vmucp_allow
