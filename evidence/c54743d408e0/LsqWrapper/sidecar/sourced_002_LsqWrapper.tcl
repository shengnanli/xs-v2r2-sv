# vmucp 白名单条目：LsqWrapper
#
# 本文件 = LsqWrapper 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/lsq lane，commit 22db5f87 上的正式 strict 跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 253592 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 2752 + Unread 278 → strict 判 PARTIAL(strict_unread!=0)；
#   receipt evidence/22db5f873939/LsqWrapper/（receipt.json sha256
#   cc7d25f397a99143509273ba4a7b52738530852ede1e03f22b0cb4dfe6e31f78）。
#   fm_predict 模型 256622 = 253592 + 2752 + 278，差额逐位指认。
#   278 个 unread 点全是 matched_nc（两侧独占 0），跑前登记（docs/lanes/lsq_prereg.md §3）预测 278：
#     loadQueue 子树 237：与 LoadQueue 自己的 run A（evidence/22db5f873939/LoadQueue）unread 集合
#       加前缀 loadQueue/ 后**逐对相等**，依据见 verif/fm_target_config/LoadQueue.tcl；
#     storeQueue 41：counter[31:0] <-> timeoutCounter[31:0]、uncacheUop_fuOpType[8:2]、REG/REG_1 <->
#       mmioStoutFireRegChain{,_1} —— 与 verif/fm_target_config/StoreQueue.tcl 记载的 41 位同一批。
#   本层胶水没有新增 unread。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上列 278 对，逐对来自 receipt 的 matched_unread_notcompared_pairs。
#   (2) 双射：278 ref <-> 278 impl，两侧名字各 278 个互不重复，每对在同一实例下；两侧独占 0。
#   (3) 真比较：passing 253592 -> 253870，正好 +278；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒；不设任何 per-target appvar。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 253870、unread 归 0、unmatched 全零、constant_reg 2752。

fm_target_vmucp_allow
