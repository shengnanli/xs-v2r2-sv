# vmucp 白名单条目：DecodeStage
#
# 本文件 = DecodeStage 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-24, agent/cb-decode 实测，evidence/e1cca4696c04/DecodeStage）----
# 六条证据（加强前采齐）：
# (1) strict 首跑（impl commit e1cca4696c04cefa5967b8cfa5cb98d1a6d3224e，vmucp 未开，
#     FM_MERGE_DUP=false，子模块闭包 16 个 golden 文件两侧同源 elaborate）：native SUCCEEDED /
#     passing 5291（Port 4755 + DFF 536）/ failing 0 / unverified 0 / unmatched 0(0) /
#     unread_ref 0 / unread_impl 0 / 无黑盒 / 无 dont_verify / constant_reg 22（golden 闭包里
#     FM 判成常量的寄存器，两侧同源），只剩 matched-unread(notcompared) 2 点让 strict 判 PARTIAL。
# (2) 这 2 点精确绑定（unread_points.txt 2 行全是 matched_nc）：
#       golden last_REG_reg   <-> impl u_core/frontendStall_probe_q_reg
#       golden last_REG_1_reg <-> impl u_core/backendStall_probe_q_reg
# (3) 双射：配对由 verif/ut/DecodeStage/fm_pins.tcl 按规则 set_user_match（只消名差，
#     fail-closed：钉不上/本族之外的 ref 死点/数量≠2 都 error），fm.log 里 DS_PIN_END n=2 miss=0 foreign=0。
# (4) 死因两侧相同：XSPerfAccumulate("frontend_stall_cycle"/"backend_stall_cycle") 的
#     GatedValidRegNext 各多产生一份与 frontendStall_last_REG/backendStall_last_REG 相同的寄存器，
#     只喂 last_probe/last_1_probe 观测线（cone-dead）；可读核 rtl/backend/DecodeStage.sv 照 golden
#     对称保留（同异步复位 0、同次态）。
# (5) 跑前登记（docs/fm_predictions/DecodeStage.json，commit e1cca469）expected=5315：
#     首跑 5291 = 5315 - 2(unread) - 22(constant_reg)，差额被逐位指认。
# (6) 不需要约束 ref，不黑盒，不 dont_verify，不改任何 appvar。
# 加强后 FM 实比这 2 对：passing 应 5291 -> 5293、failing 仍 0、unread 归 0
#（实测数字以 evidence/<commit>/DecodeStage/ 的 receipt 为准）。

fm_target_vmucp_allow
