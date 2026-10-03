# vmucp 白名单条目：FastArbiter（TL2CHICoupledL2.prefetch_train_arb，FastArbiter 家族，agent/csr-l2-leaves lane）
#
# 本文件 = FastArbiter 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-03，agent/csr-l2-leaves；跑前登记 docs/lanes/csr-l2-leaves_prereg.md）----
#   与 FastArbiter_2..7 / 28 同核（rtl/common/xs_FastArbiter_core.sv，未改动）、同一个结构死位：
#   utility.FastArbiter 的 rrGrantMask 第 0 位按构造恒 0（Scala 写 false.B，FM 判 Constant reg），
#   rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0，于是 pendingMask[0] 没有任何读者。
#   golden 与重写核同为 4 位寄存器、同一个死位；预期唯一的 unread 点（matched_nc，两侧独占 0）：
#     r:/WORK/FastArbiter/pendingMask_reg[0] <-> i:/WORK/FastArbiter/u_core/pendingMask_reg[0]
#   配对由 FM 按名字自动完成，非人工强配。本条目在首跑前登记（同族 5 个先例的同构外推），
#   首跑 receipt 的 vmucp 摘要（probe_nc_unread.list）必须恰好是上面这 1 个点，否则停下诊断。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {pendingMask_reg[0]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing = 登记 expected 112 − constant_reg 1 = 111（pendingMask[0] 进 passing）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
