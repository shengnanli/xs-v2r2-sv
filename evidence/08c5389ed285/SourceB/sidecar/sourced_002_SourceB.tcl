# vmucp 白名单条目：SourceB
#
# 本文件 = SourceB 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
# ★本目标进白名单时没有把依据写进 fm_eq.tcl★（拆分时如实记录，不补写）。
# 依据只能到 git log 里找：`git log -SSourceB -- scripts/fm_eq.tcl`。
#
# ---- 2026-09-28 补（agent/mshrctl）----
#   child FastArbiter_5 改为两侧白盒（impl 用重写件）；probes_N_waitG 改回 golden 的 7 位宽
#   （原先缩成 4 位、靠 verif/dead_ref/SourceB.json 声明 golden 独有死位；该声明已撤）。
#   于是全部 unread 点应为两侧对称 matched_nc：issueArb/pendingMask_reg[0]（FastArbiter 结构死位）
#   与 waitG 高位（恒写 0、只读 [3:0]）。精确集合与 passing 增量见 docs/lanes/mshrctl_prereg.md §2。

fm_target_vmucp_allow
