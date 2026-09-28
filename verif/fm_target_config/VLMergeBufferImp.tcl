# vmucp 白名单条目：VLMergeBufferImp
#
# 本文件 = VLMergeBufferImp 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-09-28，agent/vmergebuf lane) ----
#   lane 内诊断试跑(diagnostic-full，核字节即 commit e37a3c41 所提交的那一份，不出 receipt)：
#   native SUCCEEDED passing 24245 / failing 0 / unverified 0 / unmatched 0(0)，但有
#   115 个 matched_nc unread 点，全部两侧对称、在 golden 与核里都没有读者：
#     · brodenMergeDataReg{,_1,_2}[255:248]（3×8=24）与 brodenMergeMaskReg{,_1,_2}[31]（3）：
#       unit-stride 合并按 reg_offset(0..15) 取 [8*off+127 : 8*off] 与 mask [off+15 : off]，
#       256/32 位锁存的最高字节/最高位永远取不到（Chisel getNoAlignedSlice 的 i 只到 15）。
#     · entries_<0..15>_replayFlowNum[4:0]（80）：只有"部分重放"出队才读它
#       （flowNum := replayFlowNum），而 load 流水的 hit 恒 1（端口被常量传播删掉）→
#       needRSReplay 永远不会置位，这条读路径在两侧都被常量剪掉。
#     · VMergebufferPipelineConnect{0,1}/data_uop_exceptionVec_{6,7,15,23}（8）：store 类异常位，
#       load 版接 0 进流水缓冲、输出端也不是 load 版的端口 —— 两侧流水缓冲里的这 4 位都只写不读。
#   配对由 verif/ut/VMergeBuffer/fm_pins_pre.tcl（流水缓冲 payload，期望 2046）与
#   fm_pins.tcl（条目/锁存寄存器的机械叶名规则，4 道 fail-closed）完成，不是人工强配。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面 4 族恰好 115 位(24+3+80+8)。
#   (2) 双射：115 ref <-> 115 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 比关 vmucp 的试跑多 115（24245 -> 24360）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与两个 pin 文件都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
