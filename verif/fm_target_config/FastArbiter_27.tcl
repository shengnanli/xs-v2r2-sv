# vmucp 白名单条目：FastArbiter_27（L2 CHI TXDAT 5 路 FastArbiter，agent/next200c-takeover lane）
#
# 本文件 = FastArbiter_27 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-03，agent/next200c-takeover）----
#   与 FastArbiter_2..7 / 28 同一个共享核 rtl/common/xs_FastArbiter_core.sv（已签核），同一结构死位：
#   utility.FastArbiter 的 rrGrantMask 第 0 位按构造恒 0（Scala 写 false.B），
#   rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0，于是 pendingMask[0] 没有任何读者。
#   golden 与重写核同为 N=5 位寄存器、同一个死位；配对由 FM 按名字自动完成，非人工强配。
#   预期唯一 unread 点（matched_nc，两侧独占 0）：
#     r:/WORK/FastArbiter_27/pendingMask_reg[0] <-> i:/WORK/FastArbiter_27/u_arbiter/pendingMask_reg[0]
#   常量寄存器 rrGrantMask_reg[0] 两侧对称（不进比较点）。
#   vmucp 只对本目标打开（verif/ut/Arithmetic200c/Makefile 里 fm-FastArbiter_27 的目标专属变量）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {pendingMask_reg[0]}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing = 模型 427 - constant_reg 1 = 426（docs/lanes/newrtl_next200c_prereg.md 接管节登记）；
#       vmucp 关时应为 425 + unread 1。不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
