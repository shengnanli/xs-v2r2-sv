# vmucp 白名单条目：MSHRCtl（CoupledL2 tl2chi MSHR 资源池，agent/mshrctl lane）
#
# 本文件 = MSHRCtl 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/mshrctl，commit 159b9c25 同 RTL 字节的非正式试跑，vmucp 关、无钉点）----
#   signoff-strict：native SUCCEEDED passing 10407 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 25 + Unread 5238（全部 matched_nc，FM 按名自动配对，两侧独占 0）
#   另有 sourceB 的 probes_<k>_waitG[6:4] 12 位两侧各自 unmatched unread —— 由钉点
#   verif/ut/MSHRCtl/fm_pins_pre.tcl 配上后转为两侧对称的常量寄存器（同 SourceB 目标）。
#   5238 = 16 个 MSHR × 263 + 本层 timers_0..15 1024 + 本层 REG 1 + 5 个仲裁器 pendingMask[0]：
#     每个 MSHR 263 = validCnt 64 + timer 64 + acquire_ts 64 + release_ts 64
#                   + acquire/release_period_valid_REG 2 + REG/REG_1..3 4 + state_w_pprobeackfirst 1
#   ★为什么是对称死位★：
#     · validCnt / REG* / 本层 REG：只喂 `ifndef SYNTHESIS` 断言（FM 按 SYNTHESIS 读两侧）；
#     · timer / acquire_ts / release_ts / *_period_valid_REG：只喂 MSHR 的 acquire/release_period
#       输出，MSHRCtl 只把它们接进 XSPerfHistogram（综合视图无读者）—— 在 MSHR 单独证明里它们是
#       顶层输出、被比较；放进 MSHRCtl 后才变成 unread；
#     · 本层 timers_i：只喂 XSPerfHistogram；
#     · state_w_pprobeackfirst：Scala 只写不读；
#     · pendingMask[0]：FastArbiter 结构死位（rrGrantMask[0] 恒 0）。
#   golden 与重写件同名同宽保留（寄存器字段逐字照搬），是同一批没有读者的位。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上列 5238 位。
#   (2) 双射：5238 ref <-> 5238 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 恰 +5238（登记值见 docs/lanes/mshrctl_prereg.md §4）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
