# vmucp 白名单条目：DataSRAMBank_1
#
# 本文件 = DataSRAMBank_1 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/dcache lane，本 lane 实测）----
#   基线（vmucp 关，assembly，merge_dup 默认，非正式试跑，commit 8554930b）：DataSRAMBank / _1 实测
#     native SUCCEEDED / passing 1204 / failing 0 / unmatched 0 / unread 1（matched_nc）：
#       r:/WORK/DataSRAMBank_1/REG_reg <-> i:/WORK/DataSRAMBank_1/REG_reg
#   ★为什么是对称死位★：Chisel 的 assert(RegNext(!io.w.en || PopCount(io.w.way_en) <= 1.U))
#   在 golden 里留下的寄存器 REG，只有 `ifndef SYNTHESIS 段读它；重写件（gen_datasrambank.py 生成的
#   wrapper）保留同名同义的寄存器，两侧同为无读者，FM 按同名配上，1↔1 双射。
#   四个变体的 wrapper 由同一个生成器产出、这一位的形态完全相同（_2/_4 的数字见 receipt）。
# ---- 六条证据 ----
#   (1) 精确绑定：unread 集合 = {REG}。(2) 双射 1↔1，两侧独占 0。(3) 真比较：passing +1。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：无 dont_verify / elab147 / relaxed appvar；黑盒只有审定过的厂商叶子 array_7_ext（×4）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing = 基线 + 1（DataSRAMBank / _1：1205）、unread 0、unmatched 全零。

fm_target_vmucp_allow
