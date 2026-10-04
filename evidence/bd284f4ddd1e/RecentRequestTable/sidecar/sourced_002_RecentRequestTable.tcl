# vmucp 白名单条目：RecentRequestTable
#
# 本文件 = RecentRequestTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   关 vmucp 的 lane 内诊断跑（make fm-RecentRequestTable，merge_dup 关，未出证）：native SUCCEEDED、failing 0、
#   unmatched compare 0，unread 两侧未配上的点：
#     ref  REG_reg                     —— Scala assert(!RegNext(w.fire && r.req.fire)) 的寄存器，
#                                         唯一读者是 `ifndef SYNTHESIS 断言 ⇒ 综合视图零扇出
#     impl u_core/rw_same_cycle_q_reg  —— 同一个寄存器（重写核取语义名，照抄不删）
#     impl u_core/rrTable/u_core/g_nomcp.rdata_last_REG_reg —— 共享核 xs_SRAMTemplate_core 的
#         非 holdRead 分支死寄存器；主线上它与 respReg 同方程、靠 merge_dup 合并（内层 SRAMTemplate_146
#         单独签核时同口径），故本 UT 用 merge 默认值（true），它不再出现；codex 0206 D1 另有 lane 删它。
#   REG / rw_same_cycle_q 由 verif/ut/RecentRequestTable/fm_pins.tcl 钉成一对，再由本条 vmucp 真比较。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {REG_reg <-> u_core/rw_same_cycle_q_reg}，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl，钉点字面 1（fail-closed）。
#   (3) 真比较：开 vmucp 后该点进 passing（merge 开时模型只给上界，见登记文件）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/RecentRequestTable.json
#       声明的厂商宏叶子 array_13_ext（两侧各 1，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
