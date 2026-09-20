# vmucp 白名单条目：IBuffer
#
# 本文件 = IBuffer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   IBuffer(2026-09-17 加): 6 个 unread 点全是两侧对称 matched_nc。
#          ★复核判据★: passing 7902 -> 7908(正好 +6)、failing 仍 0、unread 归 0。

fm_target_vmucp_allow
