# vmucp 白名单条目：TlbStorageWrapper_2
#
# 本文件 = TlbStorageWrapper_2 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
# ★本目标进白名单时没有把依据写进 fm_eq.tcl★（拆分时如实记录，不补写）。
# 依据只能到 git log 里找：`git log -STlbStorageWrapper_2 -- scripts/fm_eq.tcl`。

fm_target_vmucp_allow
