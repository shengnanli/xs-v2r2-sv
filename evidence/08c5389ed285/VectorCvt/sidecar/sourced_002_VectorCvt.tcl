# vmucp 白名单条目：VectorCvt（agent/vectorcvt-tree，2026-10-03）
#
# 本文件 = VectorCvt 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 加入依据（vmucp standing rule 六条）----
# 基线：signoff-strict 首跑（不开 vmucp），evidence/85859fb17ca0/VectorCvt（被证 commit 85859fb1）：
#   native SUCCEEDED / passing 1325 / failing 0 / unmatched 0 / constant_reg 71 / unread 266 /
#   无黑盒 / dont_verify=false。卡住的只有 strict 的 unread 铁律。
# (1) 精确绑定：只对本目标（FM_TOP=VectorCvt）生效。
# (2) 双射：266 个点全部是 matched_nc；ref 侧 266 个唯一点对 impl 侧 266 个唯一点，impl 名去掉
#     u_core/ 层次后与 ref 名逐字相同（golden 同名寄存器的同名位），无人工强配。
#     按寄存器分组（ref 名）：
#      1  vcvtWraper/vcvtImpl/estmate7/expAdderIn1_reg
#      1  vcvtWraper/vcvtImpl/estmate7/output1HReg_reg
#      1  vcvtWraper/vcvtImpl/fpcvt/expNotZeroSrc_reg
#      1  vcvtWraper/vcvtImpl/fpcvt/fcvtmodExpLessThanBias_reg
#     64  vcvtWraper/vcvtImpl/fpcvt/fcvtmodFracReg_reg
#      1  vcvtWraper/vcvtImpl/fpcvt/fcvtmodNxReg_reg
#     11  vcvtWraper/vcvtImpl/fpcvt/fcvtmodTrueExpReg_reg
#     11  vcvtWraper/vcvtImpl/fpcvt/fracShiftMask_reg
#      1  vcvtWraper/vcvtImpl/fpcvt/froundExpGreaterThanMaxExp_reg
#      1  vcvtWraper/vcvtImpl/fpcvt/froundExpLessThanBias_reg
#     11  vcvtWraper/vcvtImpl/fpcvt/froundOldExp_reg
#     52  vcvtWraper/vcvtImpl/fpcvt/froundOldFrac_reg
#      1  vcvtWraper/vcvtImpl/int2fp/absIntSrc_reg
#      1  vcvtWraper/vcvtImpl/int2fp/output1HReg_reg
#      4  vcvtWraper_1/vcvtImpl/exp_normalized_5_reg0_reg
#      7  vcvtWraper_1/vcvtImpl/exp_normalized_8_reg0_reg
#      1  vcvtWraper_1/vcvtImpl/in_abs_reg0_reg
#     24  vcvtWraper_1/vcvtImpl/in_reg0_reg
#      1  vcvtWraper_1/vcvtImpl/sig_normalized_11_reg0_reg
#      1  vcvtWraper_1/vcvtImpl/sig_normalized_24_reg0_reg
#      4  vcvtWraper_2/vcvtImpl/exp_normalized_reg0_reg
#     11  vcvtWraper_2/vcvtImpl/fflags0_reg1_reg
#     11  vcvtWraper_2/vcvtImpl/in_reg0_reg
#      8  vcvtWraper_2/vcvtImpl/rpath_sig_shifted_reg0_reg
#      1  vcvtWraper_2/vcvtImpl/sig_normalized_reg0_reg
#      4  vcvtWraper_3/vcvtImpl/exp_normalized_reg0_reg
#     11  vcvtWraper_3/vcvtImpl/fflags0_reg1_reg
#     11  vcvtWraper_3/vcvtImpl/in_reg0_reg
#      8  vcvtWraper_3/vcvtImpl/rpath_sig_shifted_reg0_reg
#      1  vcvtWraper_3/vcvtImpl/sig_normalized_reg0_reg
#     性质：golden 自身就不读的位（寄存器存满宽度、下游只用其中一部分；FP_INCVT 的
#     fround/fcvtmod 通路在本实例里输入恒 0），两侧结构对称、同为死位。
# (3) 复核判据（跑前登记）：开 vmucp 后 passing 必须正好 = 1325 + 266 = 1591，
# (4) failing / unverified / aborted / unread / unmatched 全 0；
# (5) dont_verify=false、黑盒数不变（0）、不改其它 appvar；
# (6) 摘要：开 vmucp 是让 FM 多证 266 个点，不是豁免。任何一条不满足即停下诊断。

fm_target_vmucp_allow
