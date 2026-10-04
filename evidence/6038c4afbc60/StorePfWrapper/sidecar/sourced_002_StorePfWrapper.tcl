# vmucp 白名单条目：StorePfWrapper
#
# 本文件 = StorePfWrapper 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/backend-misc，跑前登记 docs/lanes/backend-misc_prereg.md）----
#   golden StorePfWrapper 只有 clock/reset 两个端口（ENABLE_SPB=false），唯一实例 serializer
#   （Serializer）内部只剩一个零扇出死指针 enqPtrExt_0 {flag 1 位, value 4 位}。与 child Serializer
#   自己的签核同一情形（verif/fm_target_config/Serializer.tcl）：全部 5 个比较点都是 unread，
#   不开 vmucp 时没有任何比较点（FM-334），vmucp 是唯一能真比较的方式。
#
# ---- 六条 ----
#   (1) 精确绑定：unread 点集合 = serializer/{enqPtrExt_0_flag_reg, enqPtrExt_0_value_reg[3:0]}，恰好 5 位。
#   (2) 双射：5 ref <-> 5 impl（impl 在 serializer/u_core/ 下同名），FM 按名配，无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为 5 = fm_predict 模型（寄存器 5 + 输出 0）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；child 两侧白盒，无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#
# ---- 本目标专属 appvar：verification_assume_reg_init none（方向是加强，同 Serializer.tcl）----
#   默认 Auto 以复位值为初态做常量分析：复位后指针停在 (0,0)、从此不动，5 位全被判常数、移出比较集合，
#   随即 FM-334 无比较点。设 none 取消初态假设 ⇒ 5 个点的次态函数在任意当前状态下都被比，只增不减。

fm_target_vmucp_allow
fm_target_appvar verification_assume_reg_init none
