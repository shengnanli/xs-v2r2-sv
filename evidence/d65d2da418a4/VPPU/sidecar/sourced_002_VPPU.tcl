# vmucp 白名单条目：VPPU
#
# 本文件 = VPPU 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-03，agent/fpu-parents lane misc3 group，★跑前登记，未做任何 FM 试跑★）----
#   VPPU 的 child Permutation 两侧白盒（ref golden / impl 本仓重写件 rtl/backend/Permutation.sv）。
#   Permutation 自己的签核（evidence/e7e43874c72f/Permutation，verif/fm_target_config/Permutation.tcl）
#   已量到 128 个两侧对称的死位（matched unread，无钉点）：
#     vmask_uop_reg0[127:16]（112 位）、vs1_next_reg0[127:120]（8 位）、vs1_next_reg1[127:120]（8 位）。
#   ★为什么在 VPPU 层仍是死位★：这些位"没有读者"是 Permutation 内部的结构事实（读者只读 [15:0] /
#   只读 [119:0]），与 Permutation 的输入怎么接无关；VPPU 只是把 io_out_vd 原样送出，不新增读者。
#   VPPU 自己的寄存器（valid 链 2 位 + perf/seqNum 两级 1282 位）全部有读者（输出端口），不产生新的 unread。
#
# ---- 跑前预登记的复核判据（以正式 receipt 为准；与此不符即停诊断，不改判据去圆）----
#   (1) 精确绑定：unread 点集合 = vperms 内 vmask_uop_reg0[127:16] ∪ vs1_next_reg0[127:120] ∪ vs1_next_reg1[127:120]，
#       恰好 128 位（ref 在 VPPU/vperms 下，impl 在 VPPU/u_core/u_vperms/u_core 下）。
#   (2) 双射：128 ref <-> 128 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：vmucp 开后 passing 比"不开"多正好 128；unread 归 0。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（child 全两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。

fm_target_vmucp_allow
