# vmucp 白名单条目：StoreUnit
#
# 本文件 = StoreUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-10-02，agent/storeunit-vsplit lane，非正式试跑：活动工作树未提交字节，
#      FM_MODE=diagnostic-full、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 7399 / failing 0（未截断）/ unmatched 六项全 0 / constant_reg 0，
#   但 unread_notcompared = 84 → strict 会判 PARTIAL(strict_unread!=0)。84 个点全部 matched_nc
#   （寄存器保持 golden 展平名，FM 自己按名配上；两侧独占 0，无 fm_pins、无人工强配），
#   按机制分四类，两侧都是同一死位：
#   (a) s1_in_vecBaseVaddr[49:11]（39 位）与 s2_in_vecVaddrOffset[49:11]（39 位）：
#       vecVaddrOffset 的唯一读者是 s2 的 vstart = 8'(vecVaddrOffset >> veew)，veew <= 3，
#       只用得到低 11 位；vecBaseVaddr 只喂 vecVaddrOffset 的减法（低位不受高位影响）。
#   (b) s2_in_uop_fuOpType[0,1,7,8]（4 位）：s2 只用 isCbo(fuOpType) = [3:2]==11 且 [6:4]==0，
#       读 [6:2]；其余 4 位无读者（s3 不再带 fuOpType）。
#   (c) s1_in_isFirstIssue（1 位）：只有 XSPerfAccumulate(s1_in_fire_first_issue 等) 读，计数器已 DCE。
#   (d) s3_in_vecActive（1 位）：只有 XSError("In vecActive, mask complement should not be 0") 读，
#       断言在 `ifndef SYNTHESIS 里，综合口径下无读者。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 84 位（39+39+4+1+1）。
#   (2) 双射：84 ref <-> 84 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 7399 -> 7483（= 登记模型 7483 = 寄存器 4021 + 输出 3462，constant_reg 0），
#       正好 +84；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（MemTrigger_3 两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 7483、unread 归 0、unmatched 全零、constant_reg 0。

fm_target_vmucp_allow
