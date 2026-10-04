# vmucp 白名单条目：TL2CHICoupledL2
#
# 本文件 = TL2CHICoupledL2 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-top，路线 a）----
#   lane 内 diagnostic-full 诊断跑（commit 259071d60 的 detached worktree；关 vmucp、merge_dup 关、
#   钉点 283021 位 ok/bad=283021/0，未出证）：native SUCCEEDED、passing 244571、failing 0、
#   unmatched compare 0(0)、unmatched unread 0(0)、constant_reg 9718、unread = matched-unread 37783 对。
#   244571 + 37783 + 9718 = 292072 = fm_predict 模型（逐位对上）。
#   matched-unread 的分布（按顶层实例）：slices_0..3 各 8965（各 Slice 内部无读者位，与 Slice 单独签核时同一批
#   matched-unread 加实例前缀）、prefetcher 993、resp_pipeline* 364、linkMonitor 260、rxdatPipe 83、hintPipe2 66、
#   hintPipe1 33、train_pipeline* 28、rxrspPipe 23、五个仲裁器各 1（chosen 高位）、本层 grantCnt 64 +
#   grant_data_fire_first_r_counter* 4（Scala dontTouch / perf 探针残留，golden 无读者，本仓按 golden 原名保留）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准；正式证明待 codex 0214 扩授权后跑）----
#   (1) 精确绑定：unread 集合 = 上面 37783 个 matched_nc 对，unmatched_unread 两侧 0。
#   (2) 双射：37783 对里 ref 37783 个互异、impl 37783 个互异；配对来自 FM 按名 + 钉点
#       verif/ut/TL2CHICoupledL2/fm_pins_pre.tcl（scripts/gen_tl2chi_pins.py 生成，字面 283021，fail-closed；
#       桩跑出的 set_user_match 序列与诊断跑 fm.log 的 283021 条回显逐字节相同，sha256 a140c726…052a）。
#   (3) 真比较：开 vmucp 后 passing 应为 244571 + 37783 = 282354，unread 0，constant_reg 9718 不变。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒 = 厂商叶子 array_13..18_ext
#       （两侧各 46，vendor_boundary）+ ram_10x89 ×4 + ram_78x15 ×1（两侧各 5，待 codex 0214 对本父级扩授权，
#       verif/allow/TL2CHICoupledL2.json 届时声明），不新增黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
