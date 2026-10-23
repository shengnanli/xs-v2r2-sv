# vmucp 白名单条目：LoadPipe
#
# 本文件 = LoadPipe 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/dcache lane，本 lane 实测）----
#   基线（vmucp 关，signoff-strict，非正式试跑，commit 6105f46f）：
#     native SUCCEEDED / passing 1250 / failing 0 / unmatched compare points 0(0) / unread 59 matched_nc
#     + 6 个未配对 unread（golden 断言寄存器 REG_1/REG_2/REG_4 与重写件起了别名的 3 个），
#     fm_verdict PARTIAL。重写件改用 golden 同名（REG_1/2/4）后这 3 对也成为 matched_nc，共 62 对。
#   62 个 unread 点（两侧同名同位、全部 matched_nc，两侧独占 0）：
#     s1_req_vaddr[5:0]         6  —— s1 用 paddr 的块内偏移替换 vaddr 低 6 位，原低 6 位无读者
#     s1_req_vaddr_dup[5:0]     6  —— 同上（复制那份）
#     s1_req_vaddr_dup[49:48]   2  —— 数据读地址只取 [47:0]
#     s1_bank_oh[8]             1  —— (oh64 << 1) | oh64 的宽度溢出位，bankMask 只取 [7:0]
#     s2_hit_access             1  —— resp.meta_access 在 LoadUnit 侧无读者、端口被删
#     s3_hit_prefetch[0]        1  —— 只用 isFromL1Prefetch = |pf[2:1]
#     s3_vaddr[5:0],[49:14]    42  —— s3 只用 set 下标 vaddr[13:6]
#     REG_1 / REG_2 / REG_4     3  —— assert(RegNext(..)) 寄存器，只有 `ifndef SYNTHESIS 读
#   ★为什么是对称死位★：重写件照 golden 保留同一批寄存器与同样位宽（不收窄），
#   两侧死位集合逐位相同；配对是 FM 按同名自己配的，没有任何人工强配。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 62 位。
#   (2) 双射：62 ref <-> 62 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 1250 -> 1311（+61）：62 对里 REG_4 恒写 1，FM 判为常量寄存器
#       （constant_reg 1，两侧对称），不产生比较点；其余 61 对真比较。不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1311、constant_reg 正好 1（合计 = fm_predict 模型 1312 = regs 554 + outs 758）、
#   unread 归 0、unmatched 全零。（本数字出自 lane 内 vmucp 开的非正式试跑，登记在先、签核在后。）

fm_target_vmucp_allow
