# vmucp 白名单条目：IntRFReadArbiter（agent/datapath，2026-09-28）
#
# 本文件 = IntRFReadArbiter 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据 ----
# 本目标是 DataPath 的装配壳，本层只有 WBArbiter 例化与常量 ready。其中 3 个仲裁器是 N=1 变体
# （只有一路请求）。N=1 仲裁器的反饥饿状态 5 位（cancelCounter_0[2:0] / isFull_0 / hasFull）是 golden
# 自己的死逻辑：唯一一路恒为最高优先级 ⇒ ready 恒 1 ⇒ 计数器永不自增、isFull/hasFull 永不置位
# （scripts/wbarbiter_reachability.py 穷举：N=1 可达状态只有全 0；WBArbiter_3/_38/_58/_66 单独签核时的
# 同一结论见 verif/fm_target_config/WBArbiter_3.tcl）。重写核 xs_WBArbiter_core 照抄、不因 N=1 裁剪，
# 于是两侧对称死、没人读。
# lane 内非正式试跑（VlRFWBCollideChecker / IntRFReadArbiter，未出 receipt）：这些位在父层里全部成了
# **unmatched unread**（每个 N=1 仲裁器 5 个 ref 点 ↔ 5 个 impl 点，形状逐字固定，非该形状的 unread 为 0）。
# 配对由 verif/ut/DataPathArb/fm_pins.tcl 做（五层 fail-closed：结构规则 / impl 点实测存在 / 不重钉 /
# 双射计数 / 总数 = 5 × N=1 个数 且三类分计数对），unmatched unread 单开 vmucp 必然空转，所以**先配对、再加强**。
#
# ★复核判据（跑前写死，见 docs/lanes/datapath_prereg.md §A）★
#   钉点数 = 5 × 3 = 15；配对后 unread 归 0；
#   passing = 模型 273 − 常量寄存器 9 = 264（cancelCounter_0 三位被 FM 判常量，落 Not Compared/Constant reg；
#   hasFull/isFull 进 passing）；试跑两例实测正是这个形态（Vl 检查器 51−12=39、Int 读仲裁 273−9=264）。
#   failing / unverified / aborted / unmatched 全 0，无黑盒、无 dont_verify。
#   passing 不增而 unread 归 0 = 点被吞掉，不算过。
fm_target_vmucp_allow
