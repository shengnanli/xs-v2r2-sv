# vmucp 白名单条目：StrideMetaArray
#
# 本文件 = StrideMetaArray 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据(2026-10-02，agent/l1prefetch-tables lane) ----
#   首跑(signoff-strict，evidence/c30ff0182ac6/StrideMetaArray)：native SUCCEEDED、passing 981 /
#   failing 0 / unmatched 0 / constant_reg 10，validator PARTIAL 仅因 unread 2 = matched_nc 2 对：
#     r:s2_vaddr_reg[0..1] <-> i:u_core/s2_vaddr_reg[0..1]
#   成因：s2 预取地址 = s2_vaddr + (stride << 2) / (stride << 5)，输出只用结果的 [49:10]（region）与
#   [9:6]（bit_vec）。加数低 2 位恒 0，故 s2_vaddr[1:0] 不产生进位、也不直接被读；两侧同构。
#   （s2_vaddr[5:2] 会经进位影响 [6] 以上，所以它们是被读的，不在此列。）
#
# ---- 六条证据(以 evidence/ 下 receipt 为准) ----
#   (1) 精确绑定：unread 点集合恰为上面 2 对。
#   (2) 双射：FM 按名配上（matched_nc），无人工 pin。
#   (3) 真比较：开 vmucp 后 passing 应为 981 + 2 = 983 = 模型 993 - constant_reg 10
#       (10 = last_REG..last_REG_9，每项一份 RegNext(io.flush)，flush 在本配置恒 0；impl flush_q[i] 同构)。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无子模块、无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
