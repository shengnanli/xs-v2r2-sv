# vmucp 白名单条目：TLB（前端 itlb）
#
# 本文件 = TLB 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/mmuleaf lane) ----
#   关 vmucp、不钉点的诊断跑(diagnostic-full，不出证，commit 0003e61b)：native SUCCEEDED passing 11023 /
#   failing 0 / unmatched compare 0，unread = 95(95) Unmatched reference(implementation) unread points
#   （两侧各 95、名字对不上；子模块两侧白盒：ref golden、impl 重写件）。95 对全部是两侧对称的死位，
#   由 golden 自身结构决定（itlb 这个父级不读它们），重写件逐一照有：
#     (a) csr_delay（DelayN_7）两级 × 18 位：priv.{mxr,sum,vmxr,vsum,spvp,dmode,debug} 与 pmm.* ——
#         取指 TLB 不做 load 权限检查（mxr）、ifetch 让 SUM 失效、没有 hypervisor 指令（spvp）、
#         用 imode 不用 dmode、取指不做指针掩码（pmm）；
#     (b) sfence_delay（DelayN_9）两级 × 12 位：sfence.addr[11:0]（表项刷新只用 vpn = addr[49:12]）；
#     (c) entries/page_itlb_storage_fa（TLBFA）3 口 × 11 位：查询 vpn 打拍的 [37:27]；
#     (d) 本体 REG_4 / REG_5：handle_block 两条断言的 RegNext（核里 assert_resp_ready_ok / assert_miss_has_req）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上面四族恰好 95 对（2x18 + 2x12 + 3x11 + 2）。
#   (2) 双射：95 ref <-> 95 impl，由 verif/ut/TLB/fm_pins.tcl 逐位钉成对（生成器 scripts/gen_mmuleaf.py；
#       DelayN 字段偏移从重写件 payload_in 拼接现读；字面 95，fail-closed）。
#   (3) 真比较：开 vmucp 后 passing 应为 11023 + 95 = 11118 = 模型 11118（regs 9604 + outs 1514）。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；3 个子模块两侧白盒，无黑盒。
#   (6) 摘要：本文件与 fm_pins.tcl 都进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
