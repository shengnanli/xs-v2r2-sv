# vmucp 白名单条目：CtrlBlock
#
# 本文件 = CtrlBlock 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（2026-09-27，本 lane）----
#
# CtrlBlock 是装配层：Rob 两侧白盒（golden vs rtl/backend/Rob.sv）、9 个仍在重写中的 child
# 与 Rob 的 8 个 child 两侧同源 golden elaborate。这一层里 matched-but-not-compared 的点
# 只可能来自两处，两处都是**精确绑定的双射**，不是签名猜配：
#   (1) 本层 glue 的 2022 个寄存器 / 25852 位，由 verif/ut/CtrlBlock/fm_pins_pre.tcl
#       （scripts/gen_ctrlblock_pins.py 生成）在首次 match 前逐位 set_user_match；
#       其中 golden 声明 8 位、输出只取 [6:0] 的 io_toVecExcpMod_ratOldPest_*_bits_r（12 个，
#       见 rtl/backend/CtrlBlock.sv 文件头 Q7）第 7 位两侧都无读者——它们就是这一层
#       "对称内部死位"的全部来源，两侧各 12 位、逐位钉死、一一对应。
#   (2) Rob 白盒展开后的 168720 位寄存器，由 verif/ut/CtrlBlock/fm_pins.tcl（把
#       verif/ut/Rob/fm_pins.tcl 的钉点原样下移一层）在 match 后逐位 set_user_match；
#       同源 golden child 内部的点两侧按名字（同层次同名）匹配。
# 打开 vmucp 是**加强**：把这些已配对但本层锥内无读者的点也真的比一遍，比较点只增不减，
# 不黑盒、不跳点、不约束 ref（standing rule 六条：精确绑定/双射配对/passing 增/全零/
# 无 dont_verify 无新黑盒/manifest 摘要——后四条由 receipt 与对账节核）。
# 若打开后出现 failing，说明"对称死位"的判断错了，停下逐点诊断，不放宽。
fm_target_vmucp_allow
