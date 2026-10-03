# vmucp 白名单条目：HPerfCounter_21
#
# 本文件 = HPerfCounter_21 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-02，首跑 evidence/d09e1997840f/HPerfCounter_21，impl commit d09e1997）----
# signoff-strict 首跑 native SUCCEEDED / failing 0 / unmatched 0 / 无黑盒 / 无 dont_verify，
# 仅 unread 卡住：passing 66 / unread 6↔6 未配 + matched_nc 2。
# 全部是同一族：每个计数器里 event_op_0 / event_op_1 / event_op_2 / event_op_2_reg 四个 5 位
# 算子寄存器的 [4:3]。combine(a,b,op) 只看 op[2:0]（golden HPerfCounter_21.sv 的 always 块，
# 三处 ?: 只取 [0][1][2]），所以 [4:3] 两侧同为 cone-dead；golden 也是 5 位寄存器，非重写件超配。
# 配对：可读核寄存器已改成 golden 同名；HPerfMonitor_3 的实例路径差由
# verif/ut/HPerfMonitor_3/fm_pins.tcl 一一 set_user_match（期望数机械推导、fail-closed）。
# 双射：每个计数器 4 寄存器 × 2 位 × 计数器数 = 8 ↔ 8。
# 开 vmucp 后这 8 点由 FM 实际比较（加强，不是放过）。
# ★跑前复核判据★：passing 应为 66 + 8 = 74（= docs/fm_predictions/HPerfCounter_21.json 登记值），
# unread 归零，failing / unmatched 仍 0。

fm_target_vmucp_allow
