# vmucp 白名单条目：L2Top
#
# 本文件 = L2Top 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-top，路线 a）----
#   lane 内 diagnostic-full 诊断跑（commit 259071d60 的 detached worktree；关 vmucp、merge_dup 关、
#   钉点 292228 位 ok/bad=292228/0，未出证）：native SUCCEEDED、passing 257503、failing 0、
#   unmatched compare 0(0)、unmatched unread 0(0)、constant_reg 9801、unread = matched-unread 38541 对。
#   257503 + 38541 + 9801 = 305845 = fm_predict 模型（逐位对上）。
#   matched-unread 的分布：inner_l2cache 37783（与 TL2CHICoupledL2 单独诊断跑的 37783 对同一批，加 inner_l2cache/ 前缀，
#   见 verif/fm_target_config/TL2CHICoupledL2.tcl）+ 本层 TLBuffer 队列的无读者位 758（inner_ptw_to_l2_buffer 578、
#   inner_buffer 88、inner_buffers_4 86、inner_buffer_1 6）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准；正式证明待 codex 0214 扩授权、且 TL2CHICoupledL2 签核后跑）----
#   (1) 精确绑定：unread 集合 = 上面 38541 个 matched_nc 对，unmatched_unread 两侧 0。
#   (2) 双射：38541 对里 ref、impl 各 38541 个互异；配对来自 FM 按名 + 钉点 verif/ut/L2Top/fm_pins_pre.tcl
#       （scripts/gen_tl2chi_pins.py 生成，字面 292228，fail-closed；桩跑出的 set_user_match 序列与诊断跑 fm.log 的
#       292228 条回显逐字节相同，sha256 20651a20…3e0b）。
#   (3) 真比较：开 vmucp 后 passing 应为 257503 + 38541 = 296044，unread 0，constant_reg 9801 不变。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒 = 厂商叶子 array_13..18_ext
#       （两侧各 46）+ inner_l2cache 下 ram_10x89 ×4 + ram_78x15 ×1（两侧各 5，待 codex 0214 对本父级扩授权），不新增黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
