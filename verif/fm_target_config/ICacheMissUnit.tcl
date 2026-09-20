# vmucp 白名单条目：ICacheMissUnit
#
# 本文件 = ICacheMissUnit 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# ICacheMissUnit 加入依据(2026-09-14, agent/err3 实测)：本目标此前连证明都没跑起来
# （impl 侧 set_top 失败，详见本文件下面 set_top 处的"教训 B"）。根因修掉后 strict
# 首跑 native SUCCEEDED / passing 3214 / failing 0 / unverified 0 / aborted 0 /
# unmatched compare points 0 / 无黑盒 / 无 dont_verify，只剩 unread 1 点卡住。
# 该点是 TileLink Grant 的 beats1 倒计数器，ref 侧 1 个唯一点 ↔ impl 侧 1 个唯一点、
# 非 matched_nc 项为 0，严格 1↔1 双射（叶名词干不同 refill_done_r_counter vs
# grant_beat_left_q，另差一层 u_core，名字过滤配不上；在
# verif/ut/ICacheMissUnit/fm_pins.tcl 里按次态函数逐条核对后 set_user_match 钉死）。
# 两侧同为死位、同一死因：唯一读出点是 Scala assert(!(refill_done ^ last_fire))
# （ICacheMissUnit.scala:348），golden 与可读核都把它放在 `ifndef SYNTHESIS 块里，
# 而 FM 两侧都带 -define SYNTHESIS 读入 ⇒ 断言整块编译掉，计数器写了从不被读。
# 加强后 FM 实比这一点：passing 3214 -> 3215（正好 +1）、failing 仍 0、unread 归 0。

fm_target_vmucp_allow
