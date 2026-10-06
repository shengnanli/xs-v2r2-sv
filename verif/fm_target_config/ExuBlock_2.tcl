# vmucp 白名单条目：ExuBlock_2（exublock2b lane，向量执行块：exus=ExeUnit_13 / exus_1=ExeUnit_14 / exus_2=ExeUnit_15 /
#   exus_3=ExeUnit_16 / exus_4=ExeUnit_17）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 vmucp=false，不产 receipt；钉点 18261/18261）----
# native SUCCEEDED / passing 61160 / failing 0 / unmatched 0 / constant_reg 1464；unread 2101，全部 matched_nc，
# 逐实例恰为各 ExeUnit 自签核 vmucp 白名单的那组两侧对称死位，本层无新增：
#   exus   535 = verif/fm_target_config/ExeUnit_13.tcl；   exus_1 926 = ExeUnit_14.tcl；   exus_2 388 = ExeUnit_15.tcl；
#   exus_3 148 = ExeUnit_16.tcl；   exus_4 104 = ExeUnit_17.tcl 的 106 里 matched_nc 的部分（其 2 位 pdest[7] 在本层同为常量寄存器）。
# 本层自己的寄存器（各 ExeUnit 的 frm 打拍）都送进 ExeUnit 被读，不在 unread 里。
# 预期：vmucp 打开后 passing = 61160 + 2101 = 63261，passing + constant_reg 1464 = 模型 64725。

fm_target_vmucp_allow
