# vmucp 白名单条目：ExeUnit_14（exeunit14 lane，向量执行单元外壳：Vfalu=VFAlu / Vfcvt=VCVT_8 / Vipu=VIPU / VSetRvfWvf）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 vmucp=false，不产 receipt；钉点 3678/3678）----
# native SUCCEEDED / passing 13522 / failing 0 / unmatched 0 / constant_reg 504；unread 926，全部 matched_nc：
#   240 —— 外壳 inPipe_1_1_src_4[127:8]、inPipe_1_2_src_4[127:8]：golden 整 128 位打拍、下游只读 [7:0]，
#          重写核 xs_ExeUnit_core 同样整字段打拍，两侧对称死位（同 verif/fm_target_config/ExeUnit_16.tcl 的 120 位，本单元两级）；
#   4   —— 外壳 inPipe_1_2_vpu_vuopIdx[6:3]：同理，下游只读低位；
#   28  —— Vfalu 子树：同 ExeUnit_16.tcl 的 4（mgu vdIdx_r[6:3]）+ 24（两个 VectorFloatAdder）；
#   122 —— Vipu 子树：同 verif/fm_target_config/VIPU.tcl（VMask vs1[127:8] 120 + Reduction vdType[3:2] 2）；
#   532 —— Vfcvt 子树：同 verif/fm_target_config/VCVT_8.tcl 的 532 位（impl 名去 u_core/ 后与 ref 逐字相同）。
# 合计 926。预期：vmucp 打开后 passing = 13522 + 926 = 14448，passing + constant_reg 504 = 模型 14952。
#
# 六条复核判据（跑后在 docs/lanes/exeunit14_prereg.md 对账里逐条落数）：精确绑定（恰这 926 点）/ 双射 / 真比较 /
#   全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar script_closure，receipt 记 sha256。

fm_target_vmucp_allow
