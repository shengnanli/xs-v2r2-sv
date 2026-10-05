# vmucp 白名单条目：ExuBlock_1
#
# 本文件 = ExuBlock_1 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/sms-exublock1 lane）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、merge_dup 关、带 fm_pins_pre.tcl 全部 5497 条钉点，未出证）：
#   native SUCCEEDED、passing 25302、failing 0、unmatched compare 0、unmatched unread 0、constant_reg 903，
#   unread 22 位全部 matched-unread（matched_nc），且恰好是 5 个 ExeUnit 各自签核时已入白名单的那些对称死位，
#   本层没有新增：
#     exus   (ExeUnit_8)  10 位：FAlu F32/F64 加法器 close/far path 打拍 5 位 + FCVT fcvtmodTrueExpReg[4:0] 5 位
#                              （同 verif/fm_target_config/ExeUnit_8.tcl）；
#     exus_1 / exus_3 (ExeUnit_9)  各 1 位：FDivSqrt fp_format_onehot_q[2]（同 ExeUnit_9.tcl）；
#     exus_2 / exus_4 (ExeUnit_10) 各 5 位：FAlu 同上 5 位（同 ExeUnit_10.tcl）。
#   本层 5 份 frm 打拍寄存器都送进 ExeUnit 被读，不在 unread 里。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合恰为上面 22 位（ref 22 / impl 22，全部 matched）。
#   (2) 双射：22 对由 FM 配上（ExeUnit 内部名由 verif/ut/ExuBlock_1/fm_pins_pre.tcl 的 (b) 节继承的 child 钉点保证），一对一。
#   (3) 真比较：开 vmucp 后 passing 应为 25302 + 22 = 25324 = 模型 26227 − constant_reg 903
#       （903 = ExeUnit_8 299 + 2 × ExeUnit_9 30 + 2 × ExeUnit_10 272，与三者单独签核一致）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
