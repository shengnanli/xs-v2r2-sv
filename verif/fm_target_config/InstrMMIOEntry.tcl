# vmucp 白名单条目：InstrMMIOEntry
#
# 本文件 = InstrMMIOEntry 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-20，provefleet3 lane，本 lane 实测，不是引用）----
# InstrMMIOEntry 在 verif/ut/InstrUncache 的 FM_VARIANTS 里是一个独立目标，
# 但此前一直没有 receipt。原因不是它证不出来，而是：
#   该 UT 的 Makefile 对**同目录三个变体**一起打开
#   FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true，而 verif/fm_target_config/ 下
#   只有 InstrUncache.tcl 一份白名单 ⇒ make fm-InstrMMIOEntry 在 fm_eq.tcl 的
#   白名单闸上 exit 3（fm.log 末行 "matched-unread strengthening needs an explicit
#   whitelist entry; InstrMMIOEntry is not on it"），连 elaborate 都没走完。
#
# ★跑前先量基线，再决定要不要加强（README 要求的顺序）★
# 本 lane 先用 vmucp=false 跑了一次诊断（verif/ut/InstrUncache，非正式签核）：
#     native SUCCEEDED / passing 204 / failing 0 / unmatched compare points 0
#     / unread 1 ⇒ fm_verdict PARTIAL，reason=strict_unread!=0
# 那 1 个 unread 是 **unmatched** unread（fm_work/InstrMMIOEntry/unread_points.txt）：
#     ref   r:/WORK/InstrMMIOEntry/req_addr_reg[0]
#     impl  i:/WORK/InstrMMIOEntry/u_core/req_reg\[addr][0]
# 按 fm_eq.tcl 白名单区那段提醒：unmatched unread **单开 vmucp 必然空转**
# （vmucp 只作用于已配对的未读点）。所以必须先钉成一对，再开 vmucp——
# 钉点在 verif/ut/InstrUncache/fm_pins_pre.tcl 的 InstrMMIOEntry 分支。
#
# 内容 = InstrMMIOEntry 锁存的 MMIO 取指地址最低位。golden InstrMMIOEntry.sv
# 锁存 48 位 req_addr 之后只有两个读者：`_GEN_1[req_addr[2:1]]`（选 16 位半字）与
# `{req_addr[47:3], 3'h0}`（按 8 字节对齐发 Get）—— bit 0 永远没有读者。
# 可读核 rtl/frontend/InstrMMIOEntry.sv 的 latched_req_t.addr 照抄同一行为，
# 两侧同为死位，1↔1 严格双射，非本点的未读项为 0。
# 这与 InstrUncache.tcl 里记的是**同一位**：InstrUncache 顶层下唯一的寄存器实体
# 就是 entries_0 这一个 InstrMMIOEntry，所以两次基线数字（204/0/0/1）完全相同，
# 只差路径上的 entries_0/ 一层。
#
# ★这是加强不是 waiver★：打开后 FM **真去比这一位**，不是记作 Not-Compared。
# ---- 跑前预登记的复核判据（跑完必须逐条对上，对不上就是红）----
#   passing 204 -> 205（+1，正是被真比的那一位）
#   failing 0 / unmatched 六项全 0 / unread 0 / dont_verify false
#   fm.log 里出现 "INSTRMMIOENTRY_PINS: dead req_addr[0] 1 / 1 point pinned"
#   行首锚定 grep -cE "^ *Error:" 仍为 0

fm_target_vmucp_allow
