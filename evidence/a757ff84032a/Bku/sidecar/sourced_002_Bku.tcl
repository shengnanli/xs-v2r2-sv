# vmucp 白名单条目：Bku
#
# 本文件 = Bku 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# Bku 加入依据(2026-09-14)：strict 首跑 native SUCCEEDED / passing 3371 / failing 0 /
# unmatched 0，仅 unread 20 卡住。20 点**全部** matched_nc，ref 侧 20 个唯一点对
# impl 侧 20 个唯一点、非 matched_nc 项为 0，即严格双射；内容是 funcReg(功能码寄存器
# 副本)里各子模块用不到的位——countModule[3..8] / cryptoModule[0,1,2,3,5,6,7,8] /
# 顶层 funcReg_reg ↔ 可读核 func_s1_reg[0,1,4,6,7,8]，两侧同为死位。

fm_target_vmucp_allow
