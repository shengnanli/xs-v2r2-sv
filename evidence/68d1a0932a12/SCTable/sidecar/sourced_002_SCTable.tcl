# vmucp 白名单条目：SCTable
#
# 本文件 = SCTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-03，agent/bpu-tables lane) ----
#   关 vmucp 的诊断跑(diagnostic-full，不出证，commit acb4077c)：native SUCCEEDED passing 1058 /
#   failing 0 / unmatched 全 0，unread 65 全部 matched_nc（FM 按名配上，无人工强配）：
#     s1_pc[49:2] 与 s1_pc[0]（49 位）—— RegEnable(io.req.bits.pc) 存满 50 位，只有 [1]（分支槽换位）被读；
#     s1_idx[7:1]（7 位）—— s1 只用 s1_idx[0] 选 bank，高 7 位在 s1 无读者；
#     mbistPl/addrReg[7:0] + addrRdReg[7]（9 位）—— MBIST 流水子模块内部两侧对称死位
#       （ref = golden MbistPipeSc*，impl = 已签核重写件 rtl/dft/MbistPipeSc*.sv）。
#   golden 保留这些寄存器，重写核照抄（xs_SCTable_core §2 / 子模块不改）。
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合 = 上述 65 位（诊断跑 unread_points.txt 逐条）。
#   (2) 双射：65 ref <-> 65 impl，FM 按名配上（r:.../s1_pc_reg[k] <-> i:.../u_core/s1_pc_reg[k] 等）。
#   (3) 真比较：开 vmucp 后 passing 应为 1058 + 65 = 1123 = 模型 1123。
#   (4) 全零：failing / unverified / aborted / unmatched 六项全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；仅厂商叶子 array_5_ext 两侧黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
