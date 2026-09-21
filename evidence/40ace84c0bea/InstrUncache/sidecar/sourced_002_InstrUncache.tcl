# vmucp 白名单条目：InstrUncache
#
# 本文件 = InstrUncache 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   InstrUncache 加入依据(2026-09-14, PARTIAL 收口簇)：strict native SUCCEEDED /
#          passing 204 / failing 0 / unmatched compare points 0，只剩 1(1) 个
#          **unmatched** unread。verif/ut/InstrUncache/fm_pins.tcl 先把它按名钉成
#          一对（ref entries_0/req_addr_reg[0] ↔ impl entries_0/u_core/req_reg\[addr][0]），
#          于是成为 1↔1 严格双射的 matched_nc、非 matched_nc 的未读项为 0。
#          内容 = InstrMMIOEntry 锁存的 MMIO 取指地址最低位：golden
#          InstrMMIOEntry.sv 只读 req_addr[2:1](选半字) 与 req_addr[47:3](按 8 字节
#          对齐发 Get)，bit 0 两侧同为死位。打开后 FM 真去比这一位，passing 应 +1。

fm_target_vmucp_allow
