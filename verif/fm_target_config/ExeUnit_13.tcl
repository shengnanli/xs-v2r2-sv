# vmucp 白名单条目：ExeUnit_13（exeunit13 lane，向量执行单元外壳：Vfma=VFMA / Vialu=VIAluFix / Vimac=VIMacU / Vppu=VPPU）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 vmucp=false，不产 receipt；钉点 4836/4836，尚未含 VIMacU 子钉点）----
# native SUCCEEDED / passing 16030 / failing 0 / unmatched 0 / constant_reg 380；unread 515 matched_nc + 20 对未配死位：
#   360 —— 外壳 inPipe_1_{1,2,3}_src_4[127:8]：golden 整 128 位打拍、下游只读 [7:0]；重写核 xs_ExeUnit_core 同样整字段打拍
#          （同 verif/fm_target_config/ExeUnit_16.tcl、ExeUnit_14.tcl，本单元三级）；
#   12  —— 外壳 inPipe_1_{1,2,3}_vpu_vuopIdx[6:3]：同理；
#   15  —— 外壳 inPipe_1_2_fuOpType[8:5,2:0]、inPipe_1_3_fuOpType[8:5,3:0]：fuOpType 9 位整字段打拍，第 2/3 级各只一个 FU 读、
#          且只用其中几位，两侧同为死位（同 src_4 机制）；
#   128 —— Vppu 子树：同 verif/fm_target_config/VPPU.tcl 的 128 位；
#   20  —— Vimac 子树两个 VIMac64b 的 uopIdxS1/S2[5:1]：同 verif/fm_target_config/VIMacU.tcl；本 lane 把 VIMacU 子钉点
#          （verif/ut/VIMacU/fm_pins_pre.tcl，24 条）加入 scripts/gen_exeunit.py CHILD_PIN_FILES，重生成后外壳钉点 4860 条，按名配上。
# 合计 535。预期：vmucp 打开后 passing = 16030 + 535 = 16565，passing + constant_reg 380 = 模型 16945。
#
# 六条复核判据（跑后在 docs/lanes/exeunit13_prereg.md 对账里逐条落数）：精确绑定 / 双射 / 真比较 / 全零 /
#   无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
