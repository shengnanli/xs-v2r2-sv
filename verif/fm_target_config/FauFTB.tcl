# vmucp 白名单条目：FauFTB
#
# 本文件 = FauFTB 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/bpu-tables lane) ----
#   关 vmucp、不钉的诊断跑(diagnostic-full，不出证，commit 73faf56b)：native SUCCEEDED passing 4694 /
#   failing 0 / unmatched compare 0；unread = 566 matched_nc + 400(400) 两侧 unmatched unread：
#     matched_nc 566：u_bits_meta[515:1]（515，update.meta 存满 516 位只读 [0] = meta.hit）、
#       uftb_write_pc（50，只喂写入 fall-through 断言，SYNTHESIS 下无读者）、s0_fire_next_cycle（1，只喂 perf 探针）；
#     unmatched 400：BPU 公共外壳 SegmentedAddrNext 的 s2/s3 段 PC（4 dup × 2 级 × 50 位），本预测器无消费者，
#       名字两侧不同 —— 由 verif/ut/FauFTB/fm_pins_pre.tcl（scripts/gen_bpu_stagepc_pins.py）机械钉成 400 对。
#   golden 保留这些寄存器，重写核照抄（xs_FauFTB_core §3/§4/§6、共享辅助件 xs_BpuStagePc）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上述 566 + 400 位（诊断跑 unread_points.txt 逐条）。
#   (2) 双射：566 对 FM 按名配上；400 对由生成器按"段号/dup 后缀/位号"机械映射，单射由生成器断言，字面计数 400。
#   (3) 真比较：开 vmucp + 钉后 passing 应为 4694 + 566 + 400 = 5660 = 模型 5660。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（FauFTBWay ×32 两侧白盒）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
