# vmucp 白名单条目：VMask
#
# 本文件 = VMask 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（2026-10-02，agent/beleaf lane，commit 0455f4ad 上的非正式试跑 make fm-VMask，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 1027 / failing 0 / unverified 0 / unmatched 0(0)，
#   Not Compared = Constant reg 1 + Unread 120 → strict 判 PARTIAL(strict_unread!=0)。
#   120 个 unread 点全是 matched_nc（两侧独占 0，FM 按名字自己配上，无钉点）：
#     r:/WORK/VMask/vs1_reg_s1_reg[<b>]  <->  i:/WORK/VMask/u_core/vs1_reg_s1_reg[<b>]，b ∈ 8..127。
#   ★为什么是对称死位★：Scala `val vs1_reg_s1 = RegEnable(vs1, 0.U, fire)` 把 128 位 vs1 全宽打拍，
#   之后只读 `vs1_reg_s1(7, 0)`（viota/vcpop 的上一段累加值 one_sum）；[127:8] 没有任何读者。
#   golden 与重写核是同一个 128 位寄存器、同一批死位（照抄 golden 位宽，不收窄）。
#   Constant reg 1 = ele_cnt_reg_s1[0]（16>>vsew ∈ {16,8,4,2} 最低位恒 0），两侧均标常量，不进比较。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = vs1_reg_s1[127:8]，恰好 120 位。
#   (2) 双射：120 ref <-> 120 impl 全部 matched_nc，两侧独占 0。
#   (3) 真比较：passing 1027 -> 1147，正好 +120；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1147、unread 归 0、unmatched 全零、constant_reg 1。

fm_target_vmucp_allow
