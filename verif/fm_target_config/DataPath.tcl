# vmucp 白名单条目：DataPath（agent/datapath，2026-09-28）
#
# 本文件 = DataPath 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（lane 内非正式试跑实测，同字节的核逻辑，未出 receipt）----
# 试跑 run_id DataPath-20260928T151646Z-3d3b68b2（钉点 verif/ut/DataPath/fm_pins_pre.tcl 57191 条全配上）：
#   native SUCCEEDED，passing 137627，failing 0，比较点 unmatched 0(0)，Constant reg 150，
#   Unread 481 —— **全部是 matched_nc**（两侧都配上、两侧都没人读），逐类：
#     384  int_regcache_tag_<0..47>_reg[0..7]  ↔ u_core/rc_tag_q_reg[i][b]
#       6  int_regcache_enqPtr_reg[0..5]       ↔ u_core/rc_enq_ptr_q_reg[b]
#          只给 XSPerf 的"RegCache 命中率"统计用（DataPath.scala int_regcache_tag），计数器本身没有引出，
#          golden 与核都照写、都没人读。
#      17  og0_cancel_delay_<i>_reg，i ∈ {1,3,5,7,9,11,13..23} ↔ u_core/og0_cancel_delay_q_reg[i]
#          只有全局 EXU 0/2/4/6/8/10/12 会出现在某个 IQ 的唤醒源独热里（UIntExtractor 的常量位图决定），
#          其余 17 路"上拍 og0 失败的 0 拍 FU"写了没人读。
#       4  s1_srcType_r_25_0_reg[2..3] / s1_srcType_r_26_0_reg[2..3] ↔ u_core/s1_srcType_q_reg[0..1][2..3]
#          srcType 整字段 4 位打拍，选源只看 isXp / isFp 两位。
#      70  <shell>/arbiters_<m>/{hasFull_reg, isFull_0_reg} ↔ .../u_core/{has_full_q_reg, is_full_q_reg[0]}
#          35 个 N=1 WBArbiter 的反饥饿状态（与 verif/fm_target_config/<*RFWBCollideChecker|*RFReadArbiter>.tcl
#          同一结论：唯一一路恒最高优先级 ⇒ 永不置位），钉点已在匹配前配好。
#   384 + 6 + 17 + 4 + 70 = 481，与 Unread 481 精确相等；非 matched_nc 的 unread 只有 ref 侧 21 个
#   regCache/delayToWakeupQueueRCIdx_*_reg[4]（golden-only cone-dead，走 verif/dead_ref/DataPath.json）。
#
# ★vmucp standing rule 六条（跑前写死，见 docs/lanes/datapath_prereg.md §C）★
#   1. 精确绑定：上表 481 点，每类的 ref↔impl 对应由钉点文件逐条声明；
#   2. 双射：481 ref ↔ 481 impl 全部 matched_nc，两侧独占 unread 只剩 dead_ref 的 21 个 ref 点；
#   3. 真比较：passing 137627 → **138108**（正好 +481）；不增即空转、判红；
#   4. 全零：failing / unverified / aborted / 比较点 unmatched 全 0；
#   5. 无放宽：dont_verify / elab147 / relaxed_appvars 皆空，无黑盒；
#   6. 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure，receipt 记 sha256。
fm_target_vmucp_allow
