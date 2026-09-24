# vmucp 白名单条目：MemCtrl
#
# 本文件 = MemCtrl 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-24, agent/cb-rename 实测，evidence/9154088d8da0/MemCtrl）----
# 本模块**没有任何输出端口**（golden 11 端口全 input：LFST 整块与 *2Rename 输出被裁），
# 于是整个闭包（MemCtrl 7 个打拍寄存器 + WaitTable 2073 位 + SSIT 及其 4 个 SyncDataModule
# 叶子）的每一个寄存器位在基线里都是未读点：strict 首跑（impl commit 9154088d）native
# SUCCEEDED、passing 0、failing 0、unmatched compare points 0(0)、无黑盒、无 dont_verify；
# 8898 个 unmatched-unread 里 8k+ 是 SSIT 内 4 个叶子的两侧命名鸿沟（首跑 impl 侧用了
# rtl/common 可读叶子）。处置：
#   - 叶子改按 verif/ut/SSIT/Makefile 同一口径两侧读 golden 文件（它们各自是已 SUCCEEDED 的
#     独立目标），本层不重证叶子；
#   - 改名的标量寄存器由 verif/ut/MemCtrl/fm_pins.tcl 按「层次路径+叶名」钉 138 对
#     （MemCtrl 42 + waittable REG 5 + ssit 91，fail-closed）；
#   - 其余（waittable data/resetCounter、ssit 三组 debug 影子数组与 state、叶子内部）由 FM 按名配。
# 两侧同为"模块级无输出"的死因，对称。
# 跑前登记 docs/fm_predictions/MemCtrl.json：expected 18135 = 18135 DFF + 0 Port。
# 加强后 FM 实比全部寄存器：passing 应 0 -> 18135（= 登记值）、failing 0、unread 归 0。

fm_target_vmucp_allow
