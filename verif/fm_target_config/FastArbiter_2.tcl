# vmucp 白名单条目：FastArbiter_2（RequestBuffer 的 issueArb，FastArbiter 家族，agent/l2slice lane）
#
# 本文件 = FastArbiter_2 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/l2slice lane，commit 4a2638fc 上的正式跑，vmucp 关）----
#   证据：evidence/4a2638fcec95/FastArbiter_2（signoff-strict，native SUCCEEDED）
#   passing 152 / failing 0 / unverified 0 / unmatched 0，Constant reg 1，unread 1 -> strict 判 PARTIAL。
#   唯一的 unread 点（matched_nc，两侧独占 0）：
#     r:/WORK/FastArbiter_2/pendingMask_reg[0] <-> i:/WORK/FastArbiter_2/u_core/pendingMask_reg[0]
#   ★为什么是对称死位★：与 FastArbiter_3..7 / 28 同核（rtl/common/xs_FastArbiter_core.sv，未改动）、同一个结构死位：
#   utility.FastArbiter 的 rrGrantMask 第 0 位按构造恒 0，rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0，
#   pendingMask[0] 没有任何读者。配对由 FM 按名字自动完成，非人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {pendingMask_reg[0]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing 152 -> 153，正好 +1（登记 expected 154 − constant_reg 1）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
