# vmucp 白名单条目：VSegmentUnit
#
# 本文件 = VSegmentUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 12677 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 1
#   （instMicroOp_alignedType[2]：Chisel 存成 3 位但只装 {0, 2 位元素宽度}，最高位恒 0），
#   unread_notcompared = 22 → strict 会判 PARTIAL。22 个点全部 matched_nc（寄存器保持 golden 展平名，FM 按名配上；
#   两侧独占 0，无 fm_pins、无人工强配），按机制分四类，两侧都是同一死位：
#   (a) latchVaddrDup[63:50]（14 位）：Dup 副本只喂 io.rdcache.req.bits.vaddr_dup（VAddrBits=50 位），高 14 位无人读
#       （latchVaddr 本体的高位给 TLB 的 64 位 fullva，所以本体不是死位）。
#   (b) instMicroOp_uopFlowNumMask[7:4]（4 位）：elemIdxInVd = segmentIdx & uopFlowNumMask 的读者（数据拼接 / 拆分）
#       只用低 4 位（一个寄存器最多 16 个元素）。
#   (c) lowPagePaddr[2:0]（3 位）：唯一读者 paddrLow = Cat(lowPagePaddr(47,3), 0.U(3.W))。
#   (d) splitPtr_flag（1 位）：splitPtr 的 flag 只参与自身的环形加法，读数据时只用 value（队列深 8，flag 无读者）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 22 位（14+4+3+1）。
#   (2) 双射：22 ref <-> 22 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 12677 -> 12699（= 登记模型 12700 = 寄存器 10805 + 输出 1895，减 constant_reg 1），正好 +22。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（VSegmentTrigger /
#       NewPipelineConnectPipe_33 两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 12699、unread 归 0、unmatched 全零、constant_reg 1。

fm_target_vmucp_allow
