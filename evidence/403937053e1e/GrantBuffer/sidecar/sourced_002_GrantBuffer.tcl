# vmucp 白名单条目：GrantBuffer
#
# 本文件 = GrantBuffer 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-29, agent/grantbuf；vmucp standing rule 六条）----
#   不加强的 assembly 基线（evidence/4e421fc82194/GrantBuffer，commit 4e421fc8）：
#   native SUCCEEDED / passing 10679 / failing 0 / unverified 0 / aborted 0 / unmatched 0 /
#   黑盒仅 ram_10x89 r1/i1（codex 0202 审定）/ 无 dont_verify / 无 elab147 / constant_reg 4；
#   剩 1072 个 matched_nc + 1 对 unmatched_unread（ref/impl 各 1）：
#     (a) 1024  r:timers_{k}_reg[63:0]  <-> i:u_core/timers_reg[k][63:0]   k=0..15
#               perf 计时器，只被 ifndef SYNTHESIS 的 assert 读，两侧无综合读者
#     (b)   16  r:REG[_k]_reg           <-> i:u_core/validPrev_reg[k]      （fm_pins_pre.tcl 钉）
#               RegNext(inflight valid)，只喂 (a) 的计时器
#     (c)   16  r:enable_REG[_k]_reg    <-> i:u_core/histValidPrev_reg[k]  （fm_pins_pre.tcl 钉）
#               谁也不读
#     (d)   16  r:grantQueue/ram_ext/Memory_reg[k][7] <-> i:同名路径      （两侧同一 golden ram_16x25，按名配）
#               grantQueue 存储字第 7 位 = task.param[2]，出队后只进 (e)
#     (e)    1  r:grantBuf_task_param_reg[2] <-> i:u_core/gb_param_reg[2]（fm_pins_pre.tcl 钉，本次新增 → 由
#               unmatched_unread 转为 matched_nc）；D 通道 param 只有 2 位，两侧都只读 [1:0]
#   合计 1073 = 1024 + 16 + 16 + 16 + 1，逐对精确绑定、两侧一一对应（双射），没有强配到有读者的点。
#   ★跑前预登记的复核判据★：开 vmucp 后 native SUCCEEDED，failing / unverified / unmatched /
#   unread_notcompared 全 0，passing = 10679 + 1073 = 11752（恰好增 1073），黑盒仍只有 ram_10x89 r1/i1，
#   无 dont_verify；与 docs/fm_predictions/GrantBuffer.json 模型 11756 的差 4 = constant_reg 4。
#   这是证明加强（多比 1073 个状态），不是 waiver。Queue10_GrantBuffer_Anon 不在本白名单（它 unread 0）。

fm_target_vmucp_allow
