# vmucp 白名单条目：VectorIdiv（2026-10-03，agent/srt-divblocks，本 lane 实测）
#
# ---- 基线（诊断跑，signoff-strict 口径，vmucp=false，verif/ut/VectorIdiv，钉点 1600/1600 已生效）----
#   native SUCCEEDED / passing 12284 / failing 0 / unmatched 全 0 / constant reg 8 / unread 96（全部 matched）：
#     8 个 SRT 子实例（_16bit_divide_0..3、_32bit_divide_0..1、_64bit_divide_0..1）各 8 位：
#       iter_cons_reg_{0,1,3,4} 的最高 2 位（同 verif/fm_target_config/SRT16Divint*.tcl 的论证）= 64；
#     8 个 I8DivNr4 子实例（_8bit_divide_0..7）各 4 位：const_d_reg_k[9]（同 I8DivNr4.tcl）= 32。
#
# ---- standing rule 六条 ----
# 1 精确绑定：96 对全部在 verif/ut/VectorIdiv/fm_pins_pre.tcl（scripts/gen_srt16divint.py 生成，
#   返回值计数、字面守卫 1600）里逐位钉死或由其档位钉点确定。
# 2 双射：每对都是同一子实例、同一寄存器字段、同一位。
# 3 passing 正好增 unread 数：12284 -> 12380（+96）。
# 4 全零：failing / unverified / aborted / unmatched 各项 / unread 均为 0。
# 5 无 dont_verify、无黑盒（16 个子实例全部两侧白盒）。
# 6 摘要：本文件 + docs/lanes/srt-divblocks_p2_prereg.md §5。
#
# ★这是加强不是 waiver★：打开后 FM 真去比这 96 位。

fm_target_vmucp_allow
