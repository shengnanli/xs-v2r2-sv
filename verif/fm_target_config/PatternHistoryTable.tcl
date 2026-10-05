# vmucp 白名单条目：PatternHistoryTable
#
# 本文件 = PatternHistoryTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-mem-parents）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、merge_dup 关、带 fm_pins_pre.tcl 的 991 位名差钉点，未出证）：
#   native SUCCEEDED、passing 2166、failing 0、unmatched compare 0、unmatched unread 0，
#   matched-unread（matched_nc）19 位 = s3_region_vaddr[39:21]：s3 只用区域虚地址的 [20:0]
#   （region_hash_tag 取 [20:0]、跨页判断取 [2]），高 19 位只是被打拍、没有读者。两侧同名寄存器、同一死因
#   （Scala 里 s3_region_vaddr 是整个 40 位 RegEnable）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合恰为 s3_region_vaddr_reg[39:21] 两侧 19 对，无 unmatched unread。
#   (2) 双射：FM 按名配对（u_core 前缀由 verif/ut/PatternHistoryTable/fm_pins_pre.tcl 钉，scripts/gen_pht.py 生成），一对一。
#   (3) 真比较：开 vmucp 后 passing 应为 2166 + 19 = 2185 = 跑前登记的模型值。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/PatternHistoryTable.json
#       声明的厂商宏叶子 array_12_ext（两侧各 1，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
