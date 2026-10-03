# vmucp 白名单条目：VIMac64b
#
# ---- 加入依据（2026-10-02，agent/pmpchk-vimac-agt-fma lane，工作树上的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 911 / failing 0 / unmatched 0(0)，
#   Not Compared = Constant reg 80 + Unread 10 对 -> strict 判 PARTIAL(strict_unread!=0)。
#   10 个 unread 点全是 matched（两侧独占 0）：
#     r:/WORK/VIMac64b/uopIdxS1_reg[b] <-> i:/WORK/VIMac64b/u_core/uop_idx_s1_reg[b]
#     r:/WORK/VIMac64b/uopIdxS2_reg[b] <-> i:/WORK/VIMac64b/u_core/uop_idx_s2_reg[b]     b = 1..5
#   为什么是对称死位：Chisel `uopIdxS1 = RegEnable(uopIdx, fire)` / `uopIdxS2 = RegEnable(uopIdxS1, fireS1)`
#   把 6 位 uopIdx 全宽打两拍，而唯一的读者是 `widenS2 && uopIdxS2(0)`，[5:1] 没有任何读者。
#   golden 与重写核是同一对 6 位寄存器、同一批死位（照抄 golden 位宽，不收窄）。
#   配对是 FM 自己按签名/名字配上的，没有任何 set_user_match。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = uop_idx_s1[5:1] 与 uop_idx_s2[5:1]，恰好 10 位。
#   (2) 双射：10 ref <-> 10 impl 全部 matched，两侧独占 0。
#   (3) 真比较：passing 911 -> 921，正好 +10；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 921、unread 归 0、unmatched 全零、constant_reg 80。

fm_target_vmucp_allow
