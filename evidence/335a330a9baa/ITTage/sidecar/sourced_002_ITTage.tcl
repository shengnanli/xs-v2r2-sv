# vmucp 白名单条目：ITTage
#
# 本文件 = ITTage 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/bpu-tables lane；数字以 docs/lanes/bpu-tables_prereg.md §5 为准) ----
#   钉点（verif/ut/ITTage/fm_pins_pre.tcl，本层 3301 位逐位）+ 关 vmucp 的诊断跑：native SUCCEEDED，failing 0，
#   unmatched compare 0，unread 全部 matched_nc（两侧对称死位）：各表 update 口的 ghist / pc 高位（表内只用低位）、
#   update_ghist_r / update_r_pc 未读位、公共外壳 s1/s2/s3 PC 未读位、ITTageTable 子模块内 MBIST 流水地址寄存器等。
#   vmucp 把这些对称死位当真比对点去证（加强，不是放宽）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 诊断跑 unread_points.txt 逐条（全部 matched_nc）。
#   (2) 双射：本层由钉点生成器按规则单射、字面计数；子模块内按名配上。
#   (3) 真比较：开 vmucp 后 passing 增量 = 诊断跑的 matched_nc 点数。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；仅厂商叶子 array_6_ext 两侧黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
