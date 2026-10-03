# vmucp 白名单条目：PrefetchReqBuffer
#
# 本文件 = PrefetchReqBuffer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/l1prefetch-tables lane) ----
#   首跑(signoff-strict，evidence/a5e1c2945d2a/PrefetchReqBuffer)：native SUCCEEDED、passing 2792 /
#   failing 0 / unmatched compare 0 / 黑盒 0，validator PARTIAL 仅因 unread 146 = 两侧各 146 位 "Unmatched unread"：
#     (a) prev_in_req_full_vaddr[5:0] / s1_in_req_full_vaddr[5:0] / s3_tlb_resp_paddr_0[5:0]（18 位）：
#         Chisel 只用 get_block_vaddr(vaddr) = vaddr[49:6] 与 paddr(47, offsetBits)，块内偏移无读者；
#     (b) entries_i_paddrNoOffset[49:42]（16 × 8 = 128 位）：paddrNoOffset 声明为 fullVAddrBits(50) 宽，
#         写入值是 {8'h0, paddr[47:6]}，而 PF 请求只取 [41:9]（tag）/ [8:0]（set），高 8 位无读者。
#   两侧结构相同（核照 golden 字段宽度存）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合恰为上面 146 对。
#   (2) 双射：由 verif/ut/PrefetchReqBuffer/fm_pins_pre.tcl（scripts/gen_l1pf_pins.py 生成，只钉上述位，
#       146 位，fail-closed）逐位钉配；同一寄存器的其余位 FM 已按签名配上，不重复钉。
#   (3) 真比较：开 vmucp 后 passing 应为 2792 + 146 = 2938 = 模型 2938。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；两个仲裁器两侧白盒，无黑盒。
#   (6) 摘要：本文件与 fm_pins_pre.tcl 进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
