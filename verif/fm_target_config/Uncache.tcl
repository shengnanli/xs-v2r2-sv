# vmucp 白名单条目：Uncache（agent/leafmix lane）
#
# 本文件 = Uncache 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-09-28，agent/leafmix，commit 9621dbc8 同 RTL 字节的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED / passing 7416 / failing 0 / unmatched 0(0)，钉点 6757/6757 全配上，
#   unread 201 → strict 判 PARTIAL(strict_unread!=0)。201 个 unread 点全部是 matched_nc（两侧独占 0）：
#     entries_<i>_vaddr_reg[2:0]      <-> u_core/entry_vaddr_reg[i][2:0]        16 x 3 = 48
#     f1_fwdPAddr{,_1,_2}_reg[2:0]    <-> u_core/f1_paddr_reg[p][2:0]            3 x 3 =  9
#     f1_ptagMatches_r{,_1.._47}_reg[2:0] <-> u_core/f1_entry_addr_reg[p][w][2:0] 48 x 3 = 144
#   ★为什么是对称死位★（Uncache.scala）：
#     · 条目 vaddr 只在块比较里读 [49:3]（addrMatch / canMergePrimary 都先 >> BLOCK_OFFSET），
#       合并时低 3 位被改写成 resOffset，但没有任何读者；
#     · 前递 f1 的 paddr 与 RegEnable(entries(w).addr) 只用于 f1 块比较 [47:3]，
#       f1_fwdPAddr 另读 [3]（shiftMaskToHigh），[2:0] 无读者。
#   golden 与重写核同宽寄存器、同一批死位；配对由钉点（名差）+ FM 完成，非人工强配失配点。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上表 201 位，恰好这些。
#   (2) 双射：201 ref <-> 201 impl matched_nc，两侧独占 0。
#   (3) 真比较：passing = 7416 + 201 = 7617（登记值，= fm_predict expected，constant_reg 0）；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify / elab147 / relaxed_appvars 皆空；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
