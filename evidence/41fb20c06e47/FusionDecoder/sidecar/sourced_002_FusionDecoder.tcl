# vmucp 白名单条目：FusionDecoder
#
# 本文件 = FusionDecoder 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-24, agent/cb-decode 实测，evidence/5bf9d7f2e62d/FusionDecoder）----
# 六条证据（加强前采齐）：
# (1) strict 首跑（impl commit 5bf9d7f2e62d3f111a470ef0f002e432d754417a，vmucp 未开，
#     FM_MERGE_DUP=false）：native SUCCEEDED / passing 335（Port 145 + DFF 190）/ failing 0 /
#     unverified 0 / unmatched compare points 0(0) / unread_ref 0 / unread_impl 0 / 无黑盒 /
#     无 dont_verify，只剩 matched-unread(notcompared) 10 点让 strict 判 PARTIAL。
# (2) 这 10 点精确绑定：unread_points.txt 10 行全是 matched_nc，每对指令 2 个：
#       golden lastFire_reg / lastFire_<i>_reg   <-> impl u_core/lastFire_reg[<i>]
#       golden REG_reg      / REG_<i>_reg        <-> impl u_core/fireDelayed_perf_reg[<i>]
#     （i = 0..4；非 matched_nc 项为 0。）
# (3) 双射：配对由 verif/ut/FusionDecoder/fm_pins.tcl 按规则 set_user_match（只消名差，
#     fail-closed：钉不上/本族之外的 ref 死点/超过 10 个都 error），fm.log 里
#     FD_PIN_END n=10 miss=0 foreign=0。
# (4) 死因两侧相同：都是 Scala `val lastFire = RegNext(fire)` 与 XSPerfAccumulate("fused_instr")
#     的 RegNext(io.in(i).valid && io.inReady(i))，本配置下 perf 段不生成任何读者（cone-dead）；
#     可读核 rtl/backend/FusionDecoder.sv 照 golden 保留同一对寄存器（同无复位、同次态 = fire[i]）。
# (5) 跑前登记（docs/fm_predictions/FusionDecoder.json，commit 5bf9d7f）已预告
#     expected=345 与这 10 位 unread：首跑 passing 335 = 345 - 10，差额被逐位指认。
# (6) 不需要约束 ref，不黑盒，不 dont_verify，不改任何 appvar。
# 加强后 FM 实比这 10 对：passing 应 335 -> 345、failing 仍 0、unread 归 0
#（实测数字以 evidence/<commit>/FusionDecoder/ 的 receipt 为准）。

fm_target_vmucp_allow
