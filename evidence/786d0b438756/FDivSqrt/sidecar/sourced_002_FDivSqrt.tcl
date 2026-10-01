# vmucp 白名单条目：FDivSqrt
#
# 契约见 verif/fm_target_config/README.md：只许注释、fm_target_vmucp_allow、
# fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
#   唯一 unread 点是两侧共用 golden 孩子（FloatDivider 闭包
#   VectorFloatDividerR64）内部的死位，两侧同一份源、同死、matched_nc：
#       ref  r:/WORK/FDivSqrt/fdiv/u_vector_float_divider_r64/fp_format_onehot_q_reg[2]
#       impl i:/WORK/FDivSqrt/u_core/u_fdiv/u_vector_float_divider_r64/fp_format_onehot_q_reg[2]
#   成因：firtool 生成的 onehot 格式寄存器第 2 位在 golden 闭包内部就无读者
#   （两侧源文件逐字节相同，属 golden 自带的死位，与重写无关）。
#   双射核对：unread_points.txt 唯一一行 matched_nc，ref/impl 各恰 1 点，
#   寄存器与位索引相同，非 matched_nc 项为 0。
#   ★复核判据★：unread 1 -> 0，且 passing 恰好 +1（2039 -> 2040）。
#   passing 不增即空转，不算过。

fm_target_vmucp_allow
