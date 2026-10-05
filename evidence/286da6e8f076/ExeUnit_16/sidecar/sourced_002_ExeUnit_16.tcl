# vmucp 白名单条目：ExeUnit_16（exublock2 lane，向量浮点 ALU 执行单元外壳：Vfalu=VFAlu）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，vmucp=false，不产 receipt；钉点 3250/3250）----
# native SUCCEEDED / passing 6002 / failing 0 / unmatched 0 / constant_reg 362；unread 148，全部 matched_nc：
#   120 —— 外壳 inPipe_1_1_src_4[127:8]：golden 把 src_4 整 128 位打一拍、Vfalu 只读 [7:0]（dataPipe_1_src_4 = inPipe_1_1_src_4[7:0]），
#          重写核同样整字段打拍（xs_ExeUnit_core 字段 src_4，FIELD_W=128），两侧对称死位，按钉点名字配上；
#   4   —— Vfalu 外壳 mgu_io_in_info_vdIdx_r[6:3]（与 VFAlu 单独签核同一组，verif/fm_target_config/VFAlu.tcl (b)）；
#   24  —— 两个 VectorFloatAdder 子实例里的对称死位（VFAlu 单独签核那 34 对里非常量的部分，verif/ut/VFAlu/fm_pins.tcl，
#          本外壳经 scripts/gen_exeunit.py CHILD_PINS 照搬）。
# 预期：vmucp 打开后 passing = 6002 + 148 = 6150，passing + constant_reg 362 = 模型 6512。
#
# 六条复核判据（跑后在 docs/lanes/exublock2_prereg.md 对账里逐条落数）：精确绑定（恰这 148 点）/ 双射 / 真比较（vmucp 开后
#   passing 恰好 +148、unread_notcompared 0）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar
#   script_closure，receipt 记 sha256。

fm_target_vmucp_allow
