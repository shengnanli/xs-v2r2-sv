# vmucp 白名单条目：ICacheMainPipe
#
# 本文件 = ICacheMainPipe 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-22, agent/icpipes 实测，evidence/22646c6a3734/ICacheMainPipe）----
# strict 首跑（impl commit 22646c6a，vmucp 未开）：native SUCCEEDED / passing 4002
# （Port 2328 + DFF 1674）/ failing 0 / unverified 0 / unmatched compare points 0(0) /
# 无黑盒 / 无 dont_verify，只剩 matched-unread 32 点让 strict 判 PARTIAL。
# 这 32 点 = cntFtqFireInterval_reg[31:0]，FM 自己已经按名字 1↔1 配上
# （unread_points.txt 32 行全是 `matched_nc r:/WORK/ICacheMainPipe/cntFtqFireInterval_reg[b]
#   i:/WORK/ICacheMainPipe/u_core/cntFtqFireInterval_reg[b]`，非 matched_nc 项为 0）。
# 两侧同为死位、同一死因：它是 Scala XSPerfHistogram("ftq2icache_fire") 的 32 位间隔
# 计数器，本配置下 perf 段不生成任何读者，golden 只留了一根悬空的 cntFtqFireInterval_probe
# 线；可读核 rtl/frontend/ICacheMainPipe.sv 照 golden 保留同一个计数器（同复位值 0、
# 同次态：fire 拍清 1 否则 +1），因此 impl 侧对称存在同一批死位。
# 跑前登记（docs/fm_predictions/ICacheMainPipe.json）已预告这 32 位 unread。
# 不需要 fm_pins，不约束 ref，不黑盒，不 dont_verify。
# 加强后 FM 实比这 32 对：passing 应 4002 -> 4034、failing 仍 0、unread 归 0
#（实测数字以 evidence/<commit>/ICacheMainPipe/ 的 receipt 为准）。

fm_target_vmucp_allow
