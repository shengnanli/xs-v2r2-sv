# vmucp 白名单条目：PBestOffsetPrefetch
#
# 本文件 = PBestOffsetPrefetch 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-mem-parents）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、无钉点、merge_dup 关，未出证）：native SUCCEEDED、passing 957、
#   failing 0、unmatched compare 0，unread = 两侧各 353 位 "Unmatched unread"：
#     (a) delayQueue/queue_<k>_addrNoOffset[41:20]（16 项 × 22 位 = 352）：RecentRequestTable 只用写口地址
#         io_w_bits[25:6]（setIdx = [13:6]^[21:14]，tag = [25:14]），即 addrNoOffset[19:0]；高位在本父级无读者
#         （DelayQueue 单独签核时它们连到 io_out_bits，是活的）；
#     (b) rrTable/REG（1 位）：Scala assert(!RegNext(w.fire && r.req.fire)) 的寄存器，唯一读者是 `ifndef SYNTHESIS
#         断言；重写核同一个寄存器叫 u_core/rw_same_cycle_q（RecentRequestTable 单独签核时同一对，见其 tcl）。
#   两侧结构相同（重写 child 照 golden 字段宽度存）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合恰为上面 353 对。
#   (2) 双射：由 verif/ut/PBestOffsetPrefetch/fm_pins_pre.tcl（scripts/gen_l2mp_pins.py 生成，fail-closed，
#       字面 353）逐位钉配；同一寄存器其余位 FM 已按签名配上，不重复钉。
#   (3) 真比较：开 vmucp 后 passing 应为 957 + 353 = 1310 = 跑前登记的模型值。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/PBestOffsetPrefetch.json
#       声明的厂商宏叶子 array_13_ext（两侧各 1，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
