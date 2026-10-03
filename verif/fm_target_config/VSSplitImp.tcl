# vmucp 白名单条目：VSSplitImp
#
# 本文件 = VSSplitImp 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 7572 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 1（splitPipeline 的
#   s1_in_r_sew[2]：Chisel 把 2 位 vsew 零扩展成 3 位 sew 存，最高位恒 0），
#   unread_notcompared = 100 → strict 会判 PARTIAL。100 个点全部 matched_nc（三个子模块的寄存器都保持 golden
#   展平名，FM 按名配上；两侧独占 0，无 fm_pins、无人工强配），按机制分类，两侧都是同一死位：
#   (a) splitBuffer.strideOffsetReg[127:64]（64 位）：唯一读者 issueStride = strideOffsetReg(63:0)。
#   (b) VSSplitSkidBuffer.dataBuffer_baseAddr[63:50] + splitBuffer.uopq_baseAddr[63:50]（14+14 位）：
#       唯一读者 io.out.bits.basevaddr = baseAddr(49:0)。
#   (c) VSSplitSkidBuffer.dataBuffer_instType[2:1] + splitBuffer.uopq_instType[2:1]（2+2 位）+
#       splitPipeline.s1_in_r_instType[2]（1 位）：store 拆分缓冲只读 instType(0)（isIndexed），拆分流水 s1
#       只读 instType(1:0)，segment 位与"有序 indexed"位在 store 路径上无人读。
#   (d) VSSplitSkidBuffer.dataBuffer_uop_exceptionVec_{5,13,21}（3 位）：load 类异常位，store 拆分缓冲按 VstuCfg
#       选异常位（3/6/7/15/19/23），这三位无人读。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 100 位（64+14+14+2+2+1+3）。
#   (2) 双射：100 ref <-> 100 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 7572 -> 7672（= 登记模型 7673 = 寄存器 5119 + 输出 2554，减 constant_reg 1），正好 +100。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（三个子模块两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 7672、unread 归 0、unmatched 全零、constant_reg 1。

fm_target_vmucp_allow
