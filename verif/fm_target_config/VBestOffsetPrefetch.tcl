# vmucp 白名单条目：VBestOffsetPrefetch
#
# 本文件 = VBestOffsetPrefetch 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-mem-parents）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、无钉点、merge_dup 关，未出证）：native SUCCEEDED、passing 4067、
#   failing 0、unmatched compare 0，unread = 两侧各 531 位 "Unmatched unread" + 6 个 matched-unread：
#     (a) delayQueue/queue_<k>_addrNoOffset[43:20]（16 项 × 24 位 = 384）：RecentRequestTable_1 只用写口地址
#         io_w_bits[25:6]，即 addrNoOffset[19:0]；高位在本父级无读者（DelayQueue_1 单独签核时是活的）；
#     (b) rrTable/REG（1 位）：assert 专用寄存器，重写核叫 u_core/rw_same_cycle_q（同 RecentRequestTable_1.tcl）；
#     (c) reqFilter 146 位：与 PrefetchReqBuffer 单独签核时同一批（prev_in_req/s1_in_req full_vaddr[5:0]、
#         s3_tlb_resp_paddr_0[5:0]、16 项 paddrNoOffset[49:42]，见 PrefetchReqBuffer.tcl）；
#     (d) matched-unread 6 位：本层 s1_newFullAddr[5:0]（块内偏移；reqFilter 只取 full_vaddr[49:6]），两侧同名已配上。
#   两侧结构相同。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unmatched unread 集合恰为 (a)(b)(c) 531 对，matched-unread 恰为 (d) 6 对。
#   (2) 双射：(a)(b)(c) 由 verif/ut/VBestOffsetPrefetch/fm_pins_pre.tcl（scripts/gen_l2mp_pins.py 生成，fail-closed，
#       字面 531）逐位钉配；(d) FM 按名配对。
#   (3) 真比较：开 vmucp 后 passing 应为 4067 + 531 + 6 = 4604 = 跑前登记的模型值。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/VBestOffsetPrefetch.json
#       声明的厂商宏叶子 array_13_ext（两侧各 1，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
