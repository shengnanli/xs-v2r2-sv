# vmucp 白名单条目：VSMergeBufferImp
#
# 本文件 = VSMergeBufferImp 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-28，agent/vmergebuf lane) ----
#   lane 内诊断试跑(diagnostic-full，不出 receipt)：native SUCCEEDED passing 20022 /
#   failing 0 / unverified 0 / unmatched 0(0)，有 20 个 matched_nc unread 点，两侧对称、都没有读者：
#     · entries_<0..15>_isPartReplay（16）：Chisel 只在 VSMergeBufferImp 里对它 dontTouch
#       （debug 用），只写不读；核按 golden 字段集合照写（rtl/memblock/VLMergeBufferImp.sv §2）。
#     · VMergebufferPipelineConnect0/data_uop_exceptionVec_{4,5,13,21}（4）：load 类异常位，
#       store 版接 0 进流水缓冲、输出端也不是 store 版的端口 —— 两侧都只写不读。
#   配对由 verif/ut/VMergeBuffer/fm_pins_pre.tcl（流水缓冲 payload，期望 1023）与
#   fm_pins.tcl（条目寄存器的机械叶名规则，4 道 fail-closed）完成，不是人工强配。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 2 族恰好 20 位(16+4)。
#   (2) 双射：20 ref <-> 20 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 比关 vmucp 的试跑多 20（20022 -> 20042）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与两个 pin 文件都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
