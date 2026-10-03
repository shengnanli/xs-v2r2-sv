# vmucp 白名单条目：Estimate7（agent/vectorcvt-tree，2026-10-03）
#
# 本文件 = Estimate7 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（vmucp standing rule 六条）----
# 基线：signoff-strict 首跑（不开 vmucp），evidence/7d3da3d2f7fb/Estimate7（被证 RTL commit 6f573179，
#   登记 commit 7d3da3d2）：native SUCCEEDED / passing 242 / failing 0 / unmatched 0 / constant_reg 15 /
#   unread 2 / 无黑盒 / dont_verify=false。卡住的只有 strict 的 unread 铁律。
# (1) 精确绑定：只对本目标（FM_TOP=Estimate7）生效。
# (2) 双射：2 个点全部是 matched_nc；ref 侧 2 个唯一点对 impl 侧 2 个唯一点，impl 名去掉
#     u_core/ 层次后与 ref 名逐字相同（golden 同名寄存器的同名位），无人工强配。
#     按寄存器分组（ref 名）：
#      1  expAdderIn1_reg
#      1  output1HReg_reg
#     性质：golden 自身就不读的位（寄存器存满宽度、下游只用其中一部分；或 FP_INCVT 的
#     fround/fcvtmod 通路在本实例里输入恒 0），两侧结构对称、同为死位。
# (3) 复核判据（跑前登记）：开 vmucp 后 passing 必须正好 = 242 + 2 = 244，
# (4) failing / unverified / aborted / unread / unmatched 全 0；
# (5) dont_verify=false、黑盒数不变（0）、不改其它 appvar；
# (6) 摘要：开 vmucp 是让 FM 多证 2 个点，不是豁免。任何一条不满足即停下诊断。

fm_target_vmucp_allow
