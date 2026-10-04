# vmucp 白名单条目：WritebackEntry_15
#
# 本文件 = WritebackEntry_15 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-03，agent/fe-mem-misc）----
#   关 vmucp 的 lane 内诊断跑（make fm-WritebackEntry_15，未出证）：native SUCCEEDED，passing 1040 / failing 0 /
#   unmatched 0，unread 2，全部 matched_nc（两侧按名配上、两侧独占 0）：
#     (a) req_dirty_reg —— Scala `assert(!req.dirty || req.hasData)` 是它唯一的读者，断言在
#         `ifndef SYNTHESIS 里，FM 两侧都带 -define SYNTHESIS ⇒ 综合视图里零扇出。golden 有这个
#         寄存器，重写核照抄（rtl/memblock/WritebackEntry.sv 文件头已说明）。
#     (b) remain_dup_0_reg[1] —— remain_dup_0 只用 bit0 选"本拍发哪半行"，bit1 的唯一读者是它自己的
#         次态式（(remain_dup_0 | set) & ~clr），自反馈不算被读。golden 三份 remain 复制一份不少地照抄。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = {req_dirty_reg, remain_dup_0_reg[1]}，恰好 2 位。
#   (2) 双射：2 ref <-> 2 impl（u_core/ 下同名），FM 按名配上，无钉点。
#   (3) 真比较：开 vmucp 后 passing 应为 1040 + 2 = 1042 = fm_predict 模型（寄存器 674 + 输出 368）。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无子模块、无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
