# vmucp 白名单条目：Permutation
#
# 本文件 = Permutation 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-02，agent/beleaf lane，commit 932b42bb 上的非正式试跑 make fm-Permutation，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 3330 / failing 0 / unverified 0 / unmatched 0(0)，
#   Not Compared = Constant reg 14 + Unread 128 → strict 判 PARTIAL(strict_unread!=0)。
#   128 个 unread 点全是 matched_nc（两侧独占 0，FM 按名字自己配上，无钉点）：
#     r:/WORK/Permutation/vmask_uop_reg0_reg[16..127]  <-> i:.../u_core/vmask_uop_reg0_reg[16..127]   112 位
#     r:/WORK/Permutation/vs1_next_reg0_reg[120..127]  <-> i:.../u_core/vs1_next_reg0_reg[120..127]    8 位
#     r:/WORK/Permutation/vs1_next_reg1_reg[120..127]  <-> i:.../u_core/vs1_next_reg1_reg[120..127]    8 位
#   ★为什么是对称死位★：
#     · Scala `vmask_uop_reg0 = RegEnable(vmask_uop, fire)` 打满 128 位，但唯一读者 vmask_byte_strb_reg0(i)
#       只读 vmask_uop_reg0(i / 2^sew)，i < 16 ⇒ 只用 [15:0]；
#     · `vs1_next_reg1 = RegEnable(vs1_next_reg0, fire_reg0)` 打满 128 位，唯一读者是 vcompress 计数 uop 的
#       输出 Cat(ones_sum_eles_reg1, vs1_next_reg1(119, 0)) ⇒ [127:120] 无读者，倒推 vs1_next_reg0[127:120] 也无读者。
#   golden 与重写核是同一批寄存器、同一批死位（照抄 golden 位宽，不收窄）。
#   Constant reg 14（两侧都标常量，不进比较）：base_reg0[3:0] / vs2_bytes_min_reg0[3:0]（= 16×vs2Id）、
#   ele_cnt_reg0[0]（16>>sew 恒偶）、vlmax_bytes_reg0[0] / vs2_bytes_max_reg0[0]（2/4/8/16 或 16×k）、
#   out_previous_ones_sum_reg0[7:5]（5 位计数零扩展）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = vmask_uop_reg0[127:16] ∪ vs1_next_reg0[127:120] ∪ vs1_next_reg1[127:120]，恰好 128 位。
#   (2) 双射：128 ref <-> 128 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 3330 -> 3458，正好 +128；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒（child slide*Vs2VdTable 两侧白盒）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 3458、unread 归 0、unmatched 全零、constant_reg 14。

fm_target_vmucp_allow
