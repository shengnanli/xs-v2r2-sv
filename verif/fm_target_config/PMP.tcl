# vmucp 白名单条目：PMP
#
# 本文件 = PMP 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/mmuleaf lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证)：native SUCCEEDED passing 13032 / failing 0 /
#   unmatched 全 0 / constant_reg 0，unread 64 全部 matched_nc（钉点 PMP_PIN_END ok=6664 bad=0）：
#     pmpMapping_cfgMerged_{0..3} 每项的 c / atomic 两位（每个 CSR 8 项 x 2 位 = 16 位，共 64 位）——
#     PMPConfig 在 PMP 表里这两位是保留位，io.pmp 的出口没有 cfg_c / cfg_atomic（PMA 表才有），
#     golden 仍把它们存在 cfgMerged 里；重写核同样整字节存（cfg_merged[0][k]）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = PMP 表 4 个 cfg CSR 中每字节的 bit5/bit6，恰好 64 位。
#   (2) 双射：64 ref <-> 64 impl，由 verif/ut/PMP/fm_pins_pre.tcl 钉成对（生成器 scripts/gen_mmuleaf.py，
#       golden 顶层寄存器 6664 位逐位、字面计数、fail-closed）。
#   (3) 真比较：开 vmucp 后 passing 应为 13032 + 64 = 13096 = 模型 13096（regs 6664 + outs 6432）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；golden 0 child，无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
