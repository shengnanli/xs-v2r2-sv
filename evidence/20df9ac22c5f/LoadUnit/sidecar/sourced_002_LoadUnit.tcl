# vmucp 白名单条目：LoadUnit
#
# 本文件 = LoadUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-09-28，agent/loadunit lane，非正式试跑：scratch detached worktree @968025e4，
#      signoff-strict、关 vmucp、FM_FAILING_LIMIT=0，不出 receipt) ----
#   native SUCCEEDED passing 18660 / failing 0 / unmatched 六项全 0 / constant_reg 11，
#   但 unread_notcompared = 89 → strict 判 PARTIAL(strict_unread!=0)。89 个点全部 matched_nc
#   （FM 自己按名配上，两侧独占 0，无 fm_pins、无人工强配），按机制分四类，两侧都是同一死位：
#   (a) s1_in_r_vecBaseVaddr[49:11]（39 位）与 s2_in_r_vecVaddrOffset[49:11]（39 位）：
#       vecVaddrOffset 的唯一读者是 s2 的 vstart = 8'(vecVaddrOffset >> veew)，veew ≤ 3，
#       只用得到低 11 位；vecBaseVaddr 只喂 vecVaddrOffset 的减法（低位不受高位影响）。
#   (b) s2_ld_valid_dup[5:0]（6 位）+ REG_1 / REG_2：数据写使能复制与其自检断言
#       assert(RegNext(s2_valid === s2_ld_valid_dup(0) || RegNext(isHWPrefetch)))，
#       断言在 `ifndef SYNTHESIS 里，综合口径下无读者；data_wen_dup 端口已被 firtool 消掉。
#   (c) REG_3 / REG_4：NC 的 XSPerfAccumulate（nc_stld_fwd / nc_stld_fwdNotReady），计数器已 DCE。
#   (d) s2_in_r_forward_tlDchannel：s1 用过之后只剩 perf（s2_forward_req）读它。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 89 位（39+39+6+4+1）。
#   (2) 双射：89 ref <-> 89 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 18660 -> 18749（= 登记模型 18760 - constant_reg 11），正好 +89；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（MemTrigger 两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 18749、unread 归 0、unmatched 全零、constant_reg 11。

fm_target_vmucp_allow
