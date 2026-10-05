# vmucp 白名单条目：TL2CHICoupledL2
#
# 本文件 = TL2CHICoupledL2 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-05，agent/l2-top，codex 0217/0222 层次化组合）----
#   canary3（commit a49da1872 的 detached worktree，assembly，6 个 green child 以 -interface_only 读入，未出证）：
#   native SUCCEEDED、passing 19242、failing 0、unmatched compare 0(0)、constant_reg 234、
#   unread = matched_nc 736 对 + unmatched unread 243(243)。后者两侧同名、只差 impl 可读核固定实例层
#   （mbistPl/u_core/g_node_return.pipelineDataOutReg 137 位、rxdatPipe/rxrspPipe stages_0/u_core/queue/ram 83+23 位），
#   已由 scripts/gen_tl2chi_pins.py 的 CHILD_STRUCT_PINS 逐位钉成对（全宽 137/422/73，fail-closed 字面 1474）。
#   matched_nc 分布（按顶层实例）：linkMonitor 192、resp_pipeline* 4×86、hintPipe2 66、本层 grantCnt 64 +
#   grant_data_fire_first_r_counter* 4、hintPipe1 33、train_pipeline* 4×7、五个仲裁器各 1（chosen 高位）——
#   golden 无读者的 perf/调试探针与 Queue 存储无读者位，本仓按 golden 原名、原位宽保留。
#
# ---- 六条证据（以 official receipt 为准）----
#   (1) 精确绑定：unread 集合 = matched_nc 736 + 钉成对后的 243 = 979 对；unmatched_unread 两侧 0。
#   (2) 双射：979 对里 ref 互异、impl 互异；配对来自 FM 按名 + verif/ut/TL2CHICoupledL2/fm_pins_pre.tcl
#       （1474 位，fail-closed，set_user_match 逐条计数）。
#   (3) 真比较：开 vmucp 后 passing 应为 19242 + 979 = 20221，unread 0，constant_reg 不变。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒 = 6 个 green child（-interface_only，
#       verif/allow/TL2CHICoupledL2.json 逐实例绑定证书 sha256），不新增黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list / receipt.pin_scripts，receipt 记其 sha256。

fm_target_vmucp_allow
