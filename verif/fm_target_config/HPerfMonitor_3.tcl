# vmucp 白名单条目：HPerfMonitor_3
#
# 本文件 = HPerfMonitor_3 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-02，首跑 evidence/d09e1997840f/HPerfMonitor_3，impl commit d09e1997）----
# signoff-strict 首跑 native SUCCEEDED / failing 0 / unmatched 0 / 无黑盒 / 无 dont_verify，
# 仅 unread 卡住：passing 624 / unread 64↔64 全未配（实例路径不同）。
# 全部是同一族：每个计数器里 event_op_0 / event_op_1 / event_op_2 / event_op_2_reg 四个 5 位
# 算子寄存器的 [4:3]。combine(a,b,op) 只看 op[2:0]（golden HPerfCounter_21.sv 的 always 块，
# 三处 ?: 只取 [0][1][2]），所以 [4:3] 两侧同为 cone-dead；golden 也是 5 位寄存器，非重写件超配。
# 配对：可读核寄存器已改成 golden 同名；HPerfMonitor_3 的实例路径差由
# verif/ut/HPerfMonitor_3/fm_pins_pre.tcl 匹配前一一 set_user_match -type cell（期望数机械推导、fail-closed；
# 原 fm_pins.tcl 匹配后钉法因 event_op_2_reg 单元/线名二义失效，复跑 evidence/5a3282d30ab1 FAILED 16，已替换）。
# 双射：每个计数器 4 寄存器 × 2 位 × 计数器数 = 64 ↔ 64。
# 开 vmucp 后这 64 点由 FM 实际比较（加强，不是放过）。
# ★跑前复核判据★：passing 应为 624 + 64 = 688（= docs/fm_predictions/HPerfMonitor_3.json 登记值），
# unread 归零，failing / unmatched 仍 0。

fm_target_vmucp_allow
