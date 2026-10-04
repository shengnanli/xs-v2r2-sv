# vmucp 白名单条目：Serializer
#
# 本文件 = Serializer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   golden Serializer 只有 clock/reset 两个端口（ENABLE_SPB=false，入队 valid 恒 0，firtool 删光了
#   所有数据通路与输出），只剩一个死指针 enqPtrExt_0 {flag 1 位, value 4 位}，零扇出（只读它自己）。
#   因此**全部** 5 个比较点都是 unread：不开 vmucp 时 FM 报 "There are no compare points to verify
#   (FM-334)"，native 判不出结论 —— 对这个目标来说，vmucp 不是加强，而是唯一能真比较的方式。
#   第一次诊断跑（重写核用 enq_flag/enq_value 命名）实测 5(5) Unmatched unread points：零扇出的点
#   FM 不做签名分析，只能按名配。重写核随后照 Chisel 的 enqPtrExt(0).flag/.value 展平命名。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {enqPtrExt_0_flag_reg, enqPtrExt_0_value_reg[3:0]}，恰好 5 位。
#   (2) 双射：5 ref <-> 5 impl（u_core/ 下同名），FM 按名配上，无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为 0 + 5 = 5 = fm_predict 模型（寄存器 5 + 输出 0）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无子模块、无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#
# ---- 本目标专属 appvar：verification_assume_reg_init none（方向是加强）----
#   开 vmucp、默认 assume_reg_init=Auto 的诊断跑：5 个点全部落进 Not Compared / Constant reg 5，
#   随即 "There are no compare points to verify (FM-334)"、Verification NOT RUN。原因：Auto 以复位值
#   为初态做常量分析 —— 复位后指针停在 (0,0)、从此不动，于是 5 位全被判成常数、移出比较集合。
#   设成 none 取消这个初态假设 ⇒ 5 个点的次态函数在**任意**当前状态下都被比（含 value>=12 的
#   回绕区，正是 UT 注入探针覆盖的那 32 种状态），比较点只增不减（先例 LoadQueueReplay.tcl 同一条）。
#
#   UT 侧另有独立观测：verif/ut/Serializer/tb.sv 每拍给两侧注入同一随机指针、比次态（32 种取值全覆盖）。

fm_target_vmucp_allow
fm_target_appvar verification_assume_reg_init none
