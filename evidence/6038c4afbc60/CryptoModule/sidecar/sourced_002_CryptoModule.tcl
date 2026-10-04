# vmucp 白名单条目：CryptoModule
#
# 本文件 = CryptoModule 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/backend-misc，跑前登记 docs/lanes/backend-misc_prereg.md）----
# golden CryptoModule 的 funcReg 是 9 位 RegEnable(io_func, io_regEnable)，但只有 funcReg[4]
# 被读（io_out = funcReg[4] ? hash : cipher）。其余 8 位 {0,1,2,3,5,6,7,8} 在 golden 里零扇出；
# 重写件照 golden 存满 9 位、同名 funcReg（不收窄 —— 收窄会变成 golden-only 死位），两侧同为死位。
# 同一族死位在 Bku 的白名单依据里已列过（cryptoModule[0,1,2,3,5,6,7,8]，verif/fm_target_config/Bku.tcl）。
#
# ---- 六条（standing rule）----
#   (1) 精确绑定：unread 点集合 = funcReg_reg[b]，b ∈ {0,1,2,3,5,6,7,8}，恰好 8 位，两侧各 8。
#   (2) 双射：两侧寄存器同名同层级（实例名不变，重写件无 u_core 包裹），FM 按名配，无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为模型 703（寄存器 639 + 输出 64）= 未开时 695 + 8。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；child 两侧白盒，无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
