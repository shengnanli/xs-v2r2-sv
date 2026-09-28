# vmucp 白名单条目：Scheduler_2
#
# 本文件 = Scheduler_2 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
# 自动生成：verif/ut/IssueQueue_common/gen_vmucp_cfg.py —— 数字全部从下面那次未开 vmucp 的跑里摘出。
#
# ---- 加入依据（standing rule 六条）----
#   采证跑：diagnostic-full（不产 receipt），commit e075ba23，未开 vmucp，
#           native SUCCEEDED，passing 11327，failing 0，unmatched 全 0。
#   (1) 精确绑定：只有本文件打开本目标的 vmucp（Makefile 的 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS
#       由 gen_tb.py 按本文件是否存在生成）。
#   (2) 双射配对：42081 个 unread 点**全部**是 matched_nc，且逐对都是 fm_pins_pre.tcl 里的钉点
#       （vmucp_check.py：不在钉点表 0 对、未配对 0 个）；FM 自行猜配 0 对。
#       构成 = 各 IssueQueue 实例子树里与该 IQ 单签时同类的死位（条目阵列死负载、validCnt 高位、唤醒队列 fuType 未读位等）。两侧对称。
#   (3) 期望：开 vmucp 后 passing 11327 -> 53408（恰好 +42081），failing 仍 0，unread 归 0。
#       不增即空转，按 fail 处理。
#   (4) 全零：failing / unverified / unmatched / aborted 全 0。
#   (5) 无 dont_verify、无新黑盒（两侧全白盒，黑盒输出 0）。
#   (6) 摘要即本段；采证跑的 unread_points.txt 由 lane 存档（scratchpad/iqfam/diag/Scheduler_2.unread）。

fm_target_vmucp_allow
