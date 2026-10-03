# vmucp 白名单条目：SMSTrainFilter
#
# 本文件 = SMSTrainFilter 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/l1prefetch-tables lane) ----
#   首跑(signoff-strict，evidence/058ddde1d96b/SMSTrainFilter)：native SUCCEEDED、passing 2743 /
#   failing 0 / unmatched 0，validator 判 PARTIAL 仅因 unread 8 = 两侧对称的 8 位：
#     ref  enqPtrExt_3_{flag,value[2:0]}、enqPtrExt_4_{flag,value[2:0]}
#     impl u_core/enq_flag_reg[3..4]、u_core/enq_value_reg[3..4][2:0]
#   成因：Chisel enqLen = 3 load + 2 store = 5 个入队指针，但 store 训练口被上层接 0 并被 firtool 裁掉；
#   第 i 路的分配下标 = PopCount(needAlloc 前 i 路)，3 路 load 下最大为 2，所以 3/4 号指针只随 allocNum
#   前进、永远不被读。两侧结构相同（核 ENQ_PTRS=5，alloc_idx 同样最大为 2）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合恰为上面 8 位（ref 8 / impl 8）。
#   (2) 双射：enqPtrExt_k_flag <-> enq_flag_reg[k]，enqPtrExt_k_value[b] <-> enq_value_reg[k][b]，k∈{3,4}，
#       FM 按签名自动配上（unmatched 0），无人工 pin。
#   (3) 真比较：开 vmucp 后 passing 应为 2743 + 8 = 2751 = 模型 2751（constant_reg 0）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无子模块、无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
