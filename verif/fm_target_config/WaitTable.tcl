# vmucp 白名单条目：WaitTable
#
# 本文件 = WaitTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-24, agent/cb-rename 实测，evidence/9154088d8da0/WaitTable）----
# 本模块**没有任何输出端口**（golden 5 端口全 input，rdata 链路被 firtool 裁掉），
# 所以全部 2073 个寄存器位（data 1024×2 + resetCounter 20 + REG 5）在基线里都是
# matched-unread：strict 首跑（impl commit 9154088d，vmucp 未开）native SUCCEEDED、
# passing 0、failing 0、unmatched compare points 0(0)、无黑盒、无 dont_verify。
# 配对：data_<i>_reg[b] <-> data_reg[i][b] 与 resetCounter 由 FM 按名自动配；
# REG（RegNext(lvpred_timeout)）可读核名 timeout_q，由 verif/ut/MemCtrl/fm_pins.tcl 钉 5 位
# （fail-closed，期望 5）。两侧同为"没有读者"的死因（模块级无输出），对称。
# 跑前登记 docs/fm_predictions/WaitTable.json：expected 2073 = 2073 DFF + 0 Port。
# 加强后 FM 实比全部寄存器：passing 应 0 -> 2073（= 登记值）、failing 0、unread 归 0。

fm_target_vmucp_allow
