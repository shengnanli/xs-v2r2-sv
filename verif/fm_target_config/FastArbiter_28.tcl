# vmucp 白名单条目：FastArbiter_28（L2 PCredit 授予仲裁，FastArbiter 家族，agent/leafmix lane）
#
# 本文件 = FastArbiter_28 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/leafmix）----
#   与 FastArbiter_3..7 同核（rtl/common/xs_FastArbiter_core.sv），同一个结构死位：
#     r:/WORK/FastArbiter_28/pendingMask_reg[0] <-> i:/WORK/FastArbiter_28/u_core/pendingMask_reg[0]
#   ★为什么是对称死位★：utility.FastArbiter 的 rrGrantMask 第 0 位按构造恒 0（Scala 写 false.B），
#   rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0，于是 pendingMask[0] 没有任何读者。
#   golden 与重写核同为 N=80 位寄存器、同一个死位；配对由 FM 按名字自动完成，非人工强配。
#   常量寄存器 rrGrantMask_reg[0] 两侧对称（不进比较点）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {pendingMask_reg[0]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing = 登记值 240（expected 241 − constant_reg 1）；unread 实比进 passing，不进即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
