# vmucp 白名单条目：Prefetcher
#
# 本文件 = Prefetcher 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-10-04，agent/l2-top）----
#   lane 内 diagnostic-full 诊断跑（关 vmucp、merge_dup 关、带 884 位 child 钉点，未出证）：native SUCCEEDED、
#   passing 8325、failing 0、unmatched compare 0；unread = 900 个 matched-unread + 两侧各 76 位 "Unmatched unread"：
#     matched-unread 900：
#       (a) pbop / vbop 内部 884 位（与 PBestOffsetPrefetch / VBestOffsetPrefetch 单独签核时同一批，
#           见 PBestOffsetPrefetch.tcl / VBestOffsetPrefetch.tcl），由钉点配对；
#       (b) vbop/s1_newFullAddr[5:0] 6 位（同 VBestOffsetPrefetch.tcl 的 (d)），两侧同名；
#       (c) mbistPl/addrReg 9 位 + addrRdReg 1 位（诊断跑实测的集合）：MBIST 地址寄存器在本层无读者的位，两侧同名（共享核
#           xs_mbist_pipe_core 保留了 golden 的寄存器名）；
#     unmatched-unread 76（两侧结构相同、名字不同）：
#       (d) Prefetcher 自己的 recv_addr 两级延迟寄存器 [5:0]/[63:48] 共 44 位：PrefetchReceiver 只读 [47:6]；
#       (e) pftQueue/valids_0..30 共 31 位（同 PrefetchQueue.tcl）；
#       (f) mbistPl/beReg 1 位：只驱动 rrTable 内 SRAMTemplate_146 的 bore_wmask，golden 在那里无读者。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：matched-unread 恰为 (a)(b)(c) 900 对；unmatched unread 恰为 (d)(e)(f) 两侧各 76。
#   (2) 双射：(a)(d)(e)(f) 由 verif/ut/Prefetcher/fm_pins_pre.tcl（scripts/gen_prefetcher_pins.py 生成，fail-closed，
#       字面 960 = 884 + 76）逐位钉配；(b)(c) FM 按名配对。
#   (3) 真比较：开 vmucp 后 passing 应为 8325 + 900 + 76 = 9301 = 跑前登记的模型值。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 verif/allow/Prefetcher.json
#       声明的厂商宏叶子 array_13_ext（两侧各 2，vendor_macro）。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
