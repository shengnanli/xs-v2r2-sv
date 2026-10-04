# vmucp 白名单条目：Tage_SC
#
# 本文件 = Tage_SC 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/bpu-tables lane；数字以 docs/lanes/bpu-tables_prereg.md §6 为准) ----
#   关 vmucp、不钉的诊断跑：native SUCCEEDED，failing 0，unmatched compare 0；unread 分三类：
#     (a) matched_nc（FM 按名配上）：SCTable 子模块内 s1_pc / s1_idx 高位、MBIST 流水地址寄存器、
#         TageBTable 内 s1_idx、本层 update_ghist_r 未读位、updateMeta use_alt_on_na（只喂 perf 探针）——两侧对称死位；
#     (b) 两侧 unmatched unread（名字不同、无读者无签名）：公共外壳 s1/s2/s3 PC、各表 update 口的 pc / ghist 高位
#         —— 由 verif/ut/Tage_SC/fm_pins_pre.tcl（scripts/gen_bpu_stagepc_pins.py）机械钉成对，钉后同属对称死位；
#     (c) 仅 ref 侧：TageTable 子模块里 golden s1_unhashed_idx[48:1]（4 张表 × 48 位），重写 TageTable 只存被读的 [0]
#         —— 与 TageTable 自身签核时的 verif/dead_ref/TageTable*.json 同一死因，本目标以 verif/dead_ref/Tage_SC.json 精确枚举。
#   vmucp 只作用于 (a)(b)：把对称死位当真比对点去证（加强，不是放宽）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 诊断跑 unread_points.txt 逐条。
#   (2) 双射：(a) 按名配上；(b) 由生成器按规则单射、字面计数。
#   (3) 真比较：开 vmucp + 钉后 passing 增量 = (a)+(b) 的点数。
#   (4) 全零：failing / unverified / aborted / unmatched compare 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；仅厂商叶子 array_2/3/4/5_ext 两侧黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
