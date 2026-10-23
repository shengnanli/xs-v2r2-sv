# vmucp 白名单条目：SRT16Divint（2026-10-03，agent/srt-divblocks，本 lane 实测）
#
# ---- 基线（诊断跑，signoff-strict 口径，vmucp=false，verif/ut/SRT16Divint，钉点 fm_pins_pre.tcl 已生效）----
#   native SUCCEEDED / passing 1157 / failing 0 / unmatched 全 0 / constant reg 0 / unread 8（全部 matched）：
#     r:/WORK/SRT16Divint/iter_cons_reg_{0,1,3,4}_reg[20,21]
#       <-> i:/WORK/SRT16Divint/u_core/iter_cons_nz_reg_reg[{0,1,2,3}][20,21]
#
# 这 8 位是什么：iter_cons（W=22 位的 −q·d）只有两个读者——IterBlock 的整宽 CSA（逐位独立，
#   第 W-1、W-2 位的输出在 IterBlock 里被 {out[W-3:0],2'b0}/{out[W-4:0],3'b0} 截掉）与 POST 的
#   (iter_cons_reg<<2) 截回 W 位（同样丢掉最高 2 位）。⇒ 四档的最高 2 位两侧都无读者，对称死位。
#
# ---- standing rule 六条 ----
# 1 精确绑定：8 对由 FM 自己按名配上（native_facts.matched_unread_notcompared_pairs 恰为上述 8 对），
#   其中 iter_cons 的档位对应已由 fm_pins_pre.tcl（scripts/gen_srt16divint.py 生成，字面守卫）逐位钉死。
# 2 双射：同一档（golden _0/_1/_3/_4 <-> 核 nz[0..3]）同一位，k<->k。
# 3 passing 正好增 unread 数：1157 -> 1165（+8）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无黑盒（子模块全部两侧白盒）。
# 6 摘要：本文件 + docs/lanes/srt-divblocks_p2_prereg.md §5。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 8 位。

fm_target_vmucp_allow
