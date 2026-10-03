# vmucp 白名单条目：VLSplitBufferImp
#
# 本文件 = VLSplitBufferImp 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 3076 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 0，
#   unread_notcompared = 78 → strict 会判 PARTIAL。78 个点全部 matched_nc（寄存器保持 golden 展平名，FM 按名配上；
#   两侧独占 0，无 fm_pins、无人工强配），按机制分两类，两侧都是同一死位：
#   (a) strideOffsetReg[127:64]（64 位）：Chisel 里 strideOffsetReg 是 VLEN=128 位，但唯一读者是
#       issueStride = strideOffsetReg(63:0)（vaddr 是 64 位加法），高 64 位累加后无人读。
#   (b) uopq_baseAddr[63:50]（14 位）：唯一读者 io.out.bits.basevaddr = baseAddr(49:0)（VAddrBits=50）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 78 位（64+14）。
#   (2) 双射：78 ref <-> 78 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 3076 -> 3154（= 登记模型 3154 = 寄存器 1745 + 输出 1409，constant_reg 0），正好 +78。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 3154、unread 归 0、unmatched 全零、constant_reg 0。

fm_target_vmucp_allow
