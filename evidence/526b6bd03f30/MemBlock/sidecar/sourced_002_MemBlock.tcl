# vmucp 白名单条目：MemBlock（codex 0226 先例的 exact green_child 组合：72 个直接实例两侧 -interface_only）
#
# ---- 加入依据（2026-10-11，agent/memblock-asm lane，canary1：vmucp 关，同一字节 e00faf266，不产 receipt）----
#   native SUCCEEDED passing 187001 / failing 0 / unmatched 0(0) / constant_reg 10；
#   Not Compared = Unread 7，全部 matched_nc，两侧同为本层寄存器、无读者：
#     · 1 位  inner_dtlb_ld0_tlbreplay_reg_r_3 ↔ u_core/dtlbLdReplay_q_reg[3]：load DTLB 自报的 4 路重放提示打一拍，
#       第 3 路（HybridUnit / 流预取口）在本配置下没有 load 流水消费（tlb_hint.full 只给 3 条 LoadUnit）；
#     · 6 位  inner_REG_68_value ↔ u_core/hc_perf_q_reg[68]：L2 hc 性能事件 69 路打一拍，第 68 路在 golden 的
#       io_inner_hc_perfEvents 上没有对应输出（firtool 删了输出口，寄存器保留）。
#   两侧照 golden 一位不少地保留（CONVENTIONS「看起来冗余的重复结构，一份都不许少」）。
#
# ---- 六条证据（以 evidence/ 下 receipt 为准）----
#   (1) 精确绑定：unread 点集合 = 上述 7 位，均 matched_nc（canary1 unread_points.txt）。
#   (2) 双射：7 ref <-> 7 impl matched（钉点 fm_pins_pre.tcl 逐位给出），两侧独占 0。
#   (3) 真比较：passing 187001 -> 187008，正好 +7；不增即空转。
#   (4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：dont_verify_objects [] / elab147 [] / relaxed_appvars []；黑盒只有 allow 声明的 72 个 green child 实例（两侧 144 个对象）。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 正好 187008、constant_reg 10、unread 0。

fm_target_vmucp_allow
