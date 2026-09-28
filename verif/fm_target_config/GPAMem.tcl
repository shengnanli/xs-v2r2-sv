# vmucp 白名单条目：GPAMem
#
# 本文件 = GPAMem 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-24, agent/cb-rename 实测，evidence/9154088d8da0/GPAMem）----
# strict 首跑（impl commit 9154088d，vmucp 未开、无钉点）：native SUCCEEDED / passing 3983
# / failing 0 / unmatched compare points 0(0) / 无黑盒 / 无 dont_verify，
# 只剩 12 个 unmatched-unread 点（ref 12 / impl 12）让 strict 判 PARTIAL。
# 12 点全在子模块 SyncDataModuleTemplate__64entry_5（4 bank × 16 项）里，两侧同一批死位：
#   每 bank 的读地址副本 raddr_dup_0_<b>[5:4]（8 位）—— bank 内只用低 4 位，高 2 位是 bank 号；
#   输出级读地址副本 raddr_dup[3:0]（4 位）—— 输出级只用高 2 位选 bank。
# 可读核 xs_SyncDataModule 照 golden 保留同一分 bank 结构（每 bank 一份 raddr_dup、每读口
# 一份 raddr_q），所以 impl 侧对称存在同一批死位；精确绑定见 verif/ut/GPAMem/fm_pins.tcl
# （12 对，按 bank/位一一对应，fail-closed）。不约束 ref，不黑盒，不 dont_verify。
# 跑前登记 docs/fm_predictions/GPAMem.json：expected 3995 = 3938 DFF + 57 Port。
# 加强后 FM 实比这 12 对：passing 应 3983 -> 3995（= 登记值）、failing 仍 0、unread 归 0。

fm_target_vmucp_allow
