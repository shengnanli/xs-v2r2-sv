# vmucp 白名单条目：VIDiv（2026-10-03，agent/srt-divblocks，本 lane 实测）
#
# ---- 基线（诊断跑，signoff-strict 口径，vmucp=false，verif/ut/VIDiv，VectorIdiv 子树钉点 1600/1600 已生效）----
#   native SUCCEEDED / passing 13776 / failing 0 / unmatched compare 0 / constant reg 8 /
#   unread 100 = 96 matched（vidiv 子树：8 个 SRT 子实例各 8 位 iter_cons 最高 2 位 + 8 个 I8DivNr4 各 4 位
#   const_d_reg_k[9]，论证见 verif/fm_target_config/VectorIdiv.tcl）
#   + 4(4) unmatched：r:/WORK/VIDiv/outCtrl_r_vpu_vuopIdx_reg[3..6] <-> i:/WORK/VIDiv/u_core/outCtrl_r_reg\[vuopIdx][3..6]
#   （外壳锁存的 vuopIdx 只有低 3 位被 Mgu 读到，两侧对称死位；fm_pins_pre.tcl 再钉这 4 对，共 1604 点）。
#
# ---- standing rule 六条 ----
# 1 精确绑定：100 对全部在 verif/ut/VIDiv/fm_pins_pre.tcl（scripts/gen_srt16divint.py 生成，返回值计数、字面守卫 1604）。
# 2 双射：同一子实例/同一字段/同一位一一对应。
# 3 passing 正好增 unread 数：13776 -> 13876（+100）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无黑盒（VectorIdiv、Mgu 两侧白盒）。
# 6 摘要：本文件 + docs/lanes/srt-divblocks_p3_prereg.md §5。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 100 位。

fm_target_vmucp_allow
