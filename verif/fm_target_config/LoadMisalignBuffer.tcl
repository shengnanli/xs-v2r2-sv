# vmucp 白名单条目：LoadMisalignBuffer
#
# 本文件 = LoadMisalignBuffer 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据(2026-09-28，agent/lmisalign lane) ----
#   跑前登记 docs/lanes/lmisalign_prereg.md §1.3（commit f2d5a5d2，写于任何 FM 运行之前）预测
#   unread 145 位、constant_reg 267（+1 风险 lowResultShift[2]）。
#   随后一次诊断跑（make fm-LoadMisalignBuffer，FM_MODE=diagnostic-full、FM_FAILING_LIMIT=0、vmucp 关，
#   commit f2d5a5d2 同字节，不出正式 receipt）实测：native SUCCEEDED passing 7516 / failing 0 /
#   unmatched 0(0) / constant_reg 268 / unread_notcompared 145。145 个点全部 matched_nc
#   （FM 自己按名配上，两侧独占 0，无 fm_pins、无人工强配），按机制分三类，两侧都是同一死位：
#   (a) REG（1 位）：RegNext(!req_valid)，唯一读者是 XSPerfAccumulate("alloc")，本配置计数器已 DCE。
#   (b) splitLoadReqs_{0,1}_uop_fuOpType[8:2]（2×7=14 位）：发请求时标量只取子访问宽度 [1:0]
#       （再拼上 req 的 hlv/hlvx），向量直接用 req.uop.fuOpType —— 高 7 位没有读者。
#   (c) splitLoadResp_{0,1}_data[128:64]（2×65=130 位）：getShiftAndTruncateData 只取 data(63, ...)。
#   重写件照抄 golden 位宽（不收窄；收窄会变成 golden-only 死位，那才是不对称）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 145 位（1+14+130），与跑前登记逐项一致。
#   (2) 双射：145 ref <-> 145 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 7516 -> 7661（= 登记模型 7929 - constant_reg 268），正好 +145；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（叶子模块，无子实例）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 7661、unread 归 0、unmatched 全零、constant_reg 268。

fm_target_vmucp_allow
