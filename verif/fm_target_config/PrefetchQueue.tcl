# vmucp 白名单条目：PrefetchQueue
#
# 本文件 = PrefetchQueue 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/l1prefetch-tables lane) ----
#   首跑(signoff-strict，evidence/8dd734c6ac40/PrefetchQueue)：native SUCCEEDED、passing 3279 /
#   failing 0 / unmatched compare 0，validator PARTIAL 仅因 unread 31 = 两侧各 31 位 "Unmatched unread"：
#     ref  valids_0..valids_30          impl u_core/queue_valid_reg[0..30]
#   成因：Chisel `empty/full = head===tail && (!)valids.last`，只读最后一项的 valid；其余 31 个 valid 位
#   唯一的读者是它们自己的次态（PopCount 只喂被删掉的 XSPerfHistogram）。两侧同构。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合恰为上面 31 对。
#   (2) 双射：valids_i <-> u_core/queue_valid_reg[i]，i=0..30，由 verif/ut/PrefetchQueue/fm_pins_pre.tcl
#       （scripts/gen_l1pf_pins.py 生成，31 位，fail-closed）逐位钉配。
#   (3) 真比较：开 vmucp 后 passing 应为 3279 + 31 = 3310 = 模型 3310。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无子模块、无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
