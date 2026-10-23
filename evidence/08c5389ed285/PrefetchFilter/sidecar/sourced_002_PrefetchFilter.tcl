# vmucp 白名单条目：PrefetchFilter
#
# 本文件 = PrefetchFilter 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/mmuleaf lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证，commit 5cb5b16e)：native SUCCEEDED passing 2022 /
#   failing 0 / unmatched 全 0 / constant_reg 0，unread 10 全部 matched_nc（钉点 PFF_PIN_END ok=1792 bad=0）：
#     s3_tlb_resp_paddr_0[9:0] 10 位 —— TLB 回应打一拍的物理地址，回填只取 paddr[47:10] 作物理 region
#     （region_addr(paddr)），低 10 位（区域内偏移）两侧都没有读者。golden 自身结构，重写核照抄。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = s3_tlb_resp_paddr_0[9:0] 恰好 10 位。
#   (2) 双射：10 ref <-> 10 impl，由 verif/ut/PrefetchFilter/fm_pins_pre.tcl 钉成对
#       （生成器 scripts/gen_mmuleaf.py，golden 顶层寄存器 1792 位逐位、字面计数、fail-closed）。
#   (3) 真比较：开 vmucp 后 passing 应为 2022 + 10 = 2032 = 模型 2032（regs 1800 + outs 232）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；2 个仲裁器两侧白盒，无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
