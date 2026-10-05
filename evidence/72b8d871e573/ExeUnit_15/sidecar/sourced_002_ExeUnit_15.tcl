# vmucp 白名单条目：ExeUnit_15（exublock2 lane，向量 FMA / 定点整数 ALU 执行单元外壳：Vfma=VFMA 延迟 3 / VialuFix=VIAluFix 延迟 1）
#
# 本文件 = 这一个目标的 per-target 证明数据（契约见 verif/fm_target_config/README.md）。
#
# ---- 依据（诊断跑 diagnostic-full，vmucp=false，不产 receipt；钉点 4830/4830）----
# native SUCCEEDED / passing 8572 / failing 0 / unmatched 0 / constant_reg 206；unread 388，全部 matched_nc，全在外壳 inPipe：
#   360 —— inPipe_1_{1,2,3}_src_4[127:8]：golden 把 src_4 整 128 位逐级打拍、FU 只读 [7:0]；重写核同样整字段打拍
#          （xs_ExeUnit_core 字段 src_4，FIELD_W=128），两侧对称死位；
#   12  —— inPipe_1_{1,2,3}_vpu_vuopIdx[6:3]：FU 只读 vuopIdx[2:0]；
#   16  —— inPipe_1_{2,3}_fuOpType 除 bit4 外的 8 位：第 2、3 级只有 Vfma 读 fuOpType[4]。
#   全部经 gen_exeunit.py 的外壳寄存器钉点（fm_pins_pre.tcl (a)）按位配上。子 FU（VFMA / VIAluFix）内无新增死位。
# 预期：vmucp 打开后 passing = 8572 + 388 = 8960，passing + constant_reg 206 = 模型 9166。
#
# 六条复核判据（跑后在 docs/lanes/exublock2_prereg.md 对账里逐条落数）：精确绑定（恰这 388 点）/ 双射 / 真比较（vmucp 开后
#   passing 恰好 +388、unread_notcompared 0）/ 全零 / 无 dont_verify、无 elab147、无放宽 appvar、无黑盒 / 本文件进 sidecar
#   script_closure，receipt 记 sha256。

fm_target_vmucp_allow
