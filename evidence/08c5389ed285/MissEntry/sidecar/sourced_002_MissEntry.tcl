# vmucp 白名单条目：MissEntry（DCache MissQueue 的一个 MSHR 表项）
#
# 本文件 = MissEntry 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28, agent/missq lane 内 diagnostic-full 试跑，未出 receipt）----
# 首跑（vmucp 关、无钉点）：native FAILED passing 4093 / failing 7 / unmatched 10(10) /
# unread 209（matched_nc 2 + unmatched-unread 207(207)）/ constant reg 6 / 无黑盒 / 无 dont_verify。
#   · 10(10) unmatched + 7 failing = 每个请求口一份的 RegNext(primary_fire) 签名相同、FM 配不上，
#     下游 primary_ready 等 7 点跟着失配 —— 由 verif/ut/MissEntry/fm_pins_pre.tcl 逐项钉死。
#   · 207(207) unmatched-unread = 两侧同一批只喂断言/性能计数的死寄存器（REG..REG_7 8、
#     r/r_3/r_4 3、last_REG_5/6/7 3、refill_finished_last_REG 1、counter/counter_1/counter_2
#     各 64）↔ 核 §9 chk_* / w_grantlast_d1 / perf_*，同样由钉点逐项配对。
#   · matched-unread 2 = mainpipe_req_fired、should_refill_data_reg（FM 按名自动配上；
#     前者只喂 XSPerf 的 miss_refill_without_hint，后者只喂 perf 秒表的清零条件）。
# 两侧同为死位、同一死因（可读核照 golden 逐个保留，同复位/同次态，见 MissEntry.sv §9）。
# vmucp 六条：精确绑定（配对表逐项写死、计数 fail-closed，ME_PREPIN_END n=229）/ 双射（全部一对一）/
#   FM 实比（加钉点后 passing 应再增 209 个 unread 点）/ 加强后 failing 须仍为 0 /
#   无 dont_verify、无新黑盒 / 摘要写在本文件与 docs/lanes/missq_prereg.md。

fm_target_vmucp_allow
