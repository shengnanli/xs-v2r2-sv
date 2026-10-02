# vmucp 白名单条目：ActiveGenerationTable
#
# ---- 加入依据（2026-10-02，agent/pmpchk-vimac-agt-fma lane，commit 0ae2a186 字节上的非正式试跑，vmucp 关）----
#   signoff-strict：native SUCCEEDED passing 1729 / failing 0 / unmatched 0(0)，
#   Not Compared = Unread 1 对 -> strict 判 PARTIAL(strict_unread!=0)。
#   唯一的 unread 点（matched，两侧独占 0）：
#     r:/WORK/ActiveGenerationTable/s2_do_dcache_evict_last_REG_reg
#       <-> i:/WORK/ActiveGenerationTable/u_core/s2_do_evict_q_reg
#   为什么是对称死位：Chisel `s2_do_dcache_evict = GatedValidRegNext(s1_do_dcache_evict)` 只喂
#   XSPerfAccumulate("sms_agt_evict_by_plru"/"..._by_dcache")；性能计数器在本配置下被消掉，
#   firtool 却保留了这个寄存器。重写核照 golden 保留同一个寄存器（不删，删了就成 golden-only 死位）。
#   配对是 FM 自己配上的，没有任何 set_user_match。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = s2_do_evict_q，恰好 1 位。
#   (2) 双射：1 ref <-> 1 impl matched，两侧独占 0。
#   (3) 真比较：passing 1729 -> 1730，正好 +1；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；无黑盒。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 1730、unread 归 0、unmatched 全零、constant_reg 0。

fm_target_vmucp_allow
