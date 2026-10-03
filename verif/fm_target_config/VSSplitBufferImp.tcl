# vmucp 白名单条目：VSSplitBufferImp
#
# 本文件 = VSSplitBufferImp 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 3422 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 0，
#   unread_notcompared = 80 → strict 会判 PARTIAL。80 个点全部 matched_nc（寄存器保持 golden 展平名，FM 按名配上；
#   两侧独占 0，无 fm_pins、无人工强配），按机制分三类，两侧都是同一死位：
#   (a) strideOffsetReg[127:64]（64 位）：唯一读者 issueStride = strideOffsetReg(63:0)，高 64 位无人读。
#   (b) uopq_baseAddr[63:50]（14 位）：唯一读者 io.out.bits.basevaddr = baseAddr(49:0)。
#   (c) uopq_instType[2:1]（2 位）：store 变体只用 isIndexed(instType) = instType(0)
#       （load 变体另有 isOrderIndexed(instType) === "b011" 读全 3 位，所以 load 那边这两位不是死位）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 80 位（64+14+2）。
#   (2) 双射：80 ref <-> 80 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 3422 -> 3502（= 登记模型 3502 = 寄存器 1907 + 输出 1595，constant_reg 0），正好 +80。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 3502、unread 归 0、unmatched 全零、constant_reg 0。

fm_target_vmucp_allow
