# vmucp 白名单条目：FastArbiter_5（L2 FastArbiter 家族，agent/mshrctl lane）
#
# 本文件 = FastArbiter_5 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/mshrctl，commit 7a57e899 同字节的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED / failing 0 / unmatched 0(0)，Not Compared = Constant reg 1 + Unread 1
#   → strict 判 PARTIAL(strict_unread!=0)。
#   唯一的 unread 点是 matched_nc（两侧独占 0）：
#     r:/WORK/FastArbiter_5/pendingMask_reg[0] <-> i:/WORK/FastArbiter_5/u_core/pendingMask_reg[0]
#   ★为什么是对称死位★：utility.FastArbiter 的 rrGrantMask 第 0 位按构造恒 0（Scala 写 false.B），
#   rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0，于是 pendingMask[0] 没有任何读者。
#   golden 与重写核（rtl/common/xs_FastArbiter_core.sv）同为 N 位寄存器、同一个死位；
#   配对由 FM 按名字自动完成，非人工强配。常量寄存器 rrGrantMask_reg[0] 两侧对称（不进比较点）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {pendingMask_reg[0]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing 正好 +1（见 docs/lanes/mshrctl_prereg.md 的登记值）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
