# vmucp 白名单条目：CtrlUnit
#
# 本文件 = CtrlUnit 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/dcache lane，本 lane 实测）----
#   基线（vmucp 关，signoff-strict，非正式试跑，commit aec7dfd6 + 钉点）：
#     native SUCCEEDED / passing 2038 / failing 0 / unmatched compare points 0(0)
#     / unread 455 ⇒ fm_verdict PARTIAL，reason=strict_unread!=0。
#   未钉之前这 455 个是 unmatched unread（FM 不给无扇出的点做签名配对），单开 vmucp 必然空转；
#   已由 verif/ut/CtrlUnit/fm_pins_pre.tcl（scripts/gen_ctrlunit_pins.py 生成，两个出口打拍件
#   按同一布局规则全部钉 2×520=1040 对，不为死位单独强配）钉成 matched_nc：
#     r:/WORK/CtrlUnit/CtrlUnitPseudoErrorPipelineConnect0/data_<c>_{valid,mask}_reg[b]
#       <-> i:/WORK/CtrlUnit/CtrlUnitPseudoErrorPipelineConnect0/u_core/data_reg[(7-c)*65 + ...]
#     c ∈ 1..7，每通道 1 valid + 64 mask = 65 位，共 7×65 = 455。
#   ★为什么是对称死位★：Chisel 两个注入通道共用同一个 payload 类型 Vec(8, {valid, mask})，
#   tag 通道（comp=0）只有 bank 0 那一组被 tag 阵列用到，CtrlUnit 的 io_pseudoError(0) 端口在
#   golden 里就只剩 bits_0；Connect0 里通道 1..7 的 payload 寄存器仍在（NewPipelineConnectPipe_27
#   是同一个模块、两处例化），但它们的输出在 CtrlUnit 里悬空。golden 与重写件例化的是
#   同一种件、同一批悬空输出，两侧死位集合一一对应。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = Connect0 的 data_{1..7}_{valid,mask}，恰好 455 位。
#   (2) 双射：455 ref <-> 455 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 2038 -> 2493，正好 +455；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 2493（= fm_predict 模型 regs 1830 + outs 663）、unread 归 0、unmatched 全零。

fm_target_vmucp_allow
