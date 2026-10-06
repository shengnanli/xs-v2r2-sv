# vmucp 白名单条目：FloatAdder（kimi-floatadder lane，KIMI K3 起草 + Claude 收尾）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 vmucp=false，不产 receipt；钉点 pre 443+14 / post 7 全配上）----
# native SUCCEEDED / passing 1265 / failing 0 / unmatched 0 / constant_reg 167；unread 5，全部 matched_nc，
# 全部是两个子流水线自签核时 vmucp 已认定的同一组两侧对称死位：
#   F32Adder：U_far_path/U_FS1/io_result_r_2[0]、U_close_path/U_CS4_io_adder_op0_r[23]、U_close_path/U_Lshift_io_src_r[24]
#             （同 verif/fm_target_config/FloatAdderF32F16MixedPipeline.tcl）；
#   F64Adder：U_close_path/U_CS4_io_adder_op0_r[52]、U_close_path/U_Lshift_io_src_r[53]
#             （同 verif/fm_target_config/FloatAdderF64Pipeline.tcl）。
# 本层自己的寄存器（fp_format_reg / resultNeedBox）都有读者。
# 预期：vmucp 打开后 passing = 1265 + 5 = 1270，passing + constant_reg 167 = 模型 1437。

fm_target_vmucp_allow
