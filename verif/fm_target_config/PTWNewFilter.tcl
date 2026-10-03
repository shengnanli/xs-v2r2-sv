# vmucp 白名单条目：PTWNewFilter
#
# 本文件 = PTWNewFilter 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/ptwnewfilter lane) ----
#   两侧白盒（ref = golden PTWNewFilter + PTWFilterEntry/PTWFilterEntry_1/DelayN_1/RRArbiterInit_12；
#   impl = 重写件），无黑盒。关 vmucp、不钉的诊断跑(diagnostic-full，不出证，commit 0f8a2684)：
#   native SUCCEEDED passing 2014 / failing 0 / unmatched compare 0，unread 10 = 两侧 unmatched unread：
#     三张过滤表里的 inflight_counter（load 4 位 + store 3 位 + prefetch 3 位）—— 在途请求计数，
#     Chisel 里只喂 XSPerfAccumulate 与 assert，综合口径下无读者，golden 仍保留寄存器；重写核照抄。
#     两侧都没人读 → 没有功能签名可配，FM 配不上。由 verif/ut/PTWNewFilter/fm_pins_pre.tcl
#     （scripts/gen_ptwnewfilter.py 生成，fail-closed，字面计数 10）逐位钉成 matched，再由 vmucp 照比。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 三张表 inflight_counter 的 10 位，钉点文件逐位列名。
#   (2) 双射：10 ref <-> 10 impl，同一张表、同一位一一对应（PNF_PIN_END ok=10 bad=0），生成器检查单射。
#   (3) 真比较：开 vmucp 后 passing 应为 2014 + 10 = 2024 = 模型 2024（regs 1684 + outs 340）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
