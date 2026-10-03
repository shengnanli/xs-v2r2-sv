# vmucp 白名单条目：VLSplitImp
#
# 本文件 = VLSplitImp 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 7039 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 1（splitPipeline 的
#   s1_in_r_sew[2]：Chisel 把 2 位 vsew 零扩展成 3 位 sew 存，最高位恒 0），
#   unread_notcompared = 293 → strict 会判 PARTIAL。293 个点全部 matched_nc（三个子模块的寄存器都保持 golden
#   展平名，FM 按名配上；两侧独占 0，无 fm_pins、无人工强配），按机制分类，两侧都是同一死位：
#   (a) VSSplitSkidBuffer.dataBuffer_data[127:0]（128 位）：skid 缓冲照 VLSBundle 整包暂存，但 load 的拆分缓冲
#       没有 data 输入口（load 不带 store 数据），skid 的 io_out_bits_data 在本层无人接。
#   (b) splitBuffer.strideOffsetReg[127:64]（64 位）：唯一读者 issueStride = strideOffsetReg(63:0)。
#   (c) VSSplitSkidBuffer.dataBuffer_uop_fuType（35 位）+ splitPipeline.s1_in_r_uop_fuType（35 位）：
#       load 拆分缓冲的 io.out.bits.uop.fuType := FuType.vldu.U（常量），上游传下来的 fuType 在本层无人读。
#   (d) VSSplitSkidBuffer.dataBuffer_baseAddr[63:50] + splitBuffer.uopq_baseAddr[63:50]（14+14 位）：
#       唯一读者 io.out.bits.basevaddr = baseAddr(49:0)。
#   (e) VSSplitSkidBuffer.dataBuffer_uop_exceptionVec_{7,15,23}（3 位）：store 类异常位，load 拆分缓冲
#       按 VlduCfg 选异常位（3/4/5/13/19/21），这三位在本层无人读。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 293 位（128+64+35+35+14+14+3）。
#   (2) 双射：293 ref <-> 293 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 7039 -> 7332（= 登记模型 7333 = 寄存器 4961 + 输出 2372，减 constant_reg 1），正好 +293。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（三个子模块两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 7332、unread 归 0、unmatched 全零、constant_reg 1。

fm_target_vmucp_allow
