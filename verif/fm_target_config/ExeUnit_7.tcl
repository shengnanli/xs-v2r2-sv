# vmucp 白名单条目：ExeUnit_7（exublock0 lane，CSR 执行单元外壳）
#
# 本文件 = ExeUnit_7 这一个目标的 per-target 证明数据。契约见 verif/fm_target_config/README.md：
# 只许出现注释、fm_target_vmucp_allow、fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（诊断跑 diagnostic-full，关 vmucp、merge_dup 关，@28d32f0d1，未出证）----
# native SUCCEEDED / passing 30245 / failing 0 / unmatched compare 0 / constant_reg 1011；
# unread：ref-only 266、impl-only 8、matched_nc 20 对：
#   (a) ref-only 258 = verif/dead_ref/ExeUnit_7.json（CSR 190 + Fence 68，继承两 child 的 PASS_DEAD_REF 声明）—— 不在本白名单；
#   (b) 两侧同死、本白名单管的 28 对：
#       Div 6 对 —— SRT16DividerDataModule 的 aLZCReg/dLZCReg[6]、udNegReg_{0,1,3,4}[67]，与 DivUnit 单独签核
#         （verif/fm_target_config/DivUnit.tcl）同一组；ExeUnit_7 的 fm_pins_pre.tcl 按字面名钉对；
#       csr_io_csrio_exception_delay（DelayN_214）22 对 —— CSR 只读 exception 载荷的一部分：
#         exceptionVec_14 / _17 两级 ×2 = 4、gpaddr[0] 两级 = 2、gpaddr[63:56] 两级 = 16；
#         第 1 级与 gpaddr[0] 由 FM 自己配上（matched_nc 14），第 2 级 gpaddr[63:56] 8 对由 fm_pins_pre.tcl
#         按载荷位置（REG_1_bits_gpaddr[b] <-> u_core/g_chain.stage_reg[1][b+9]）钉对（诊断跑里是 ref 8 / impl 8 unmatched unread）。
#       这些位在 DelayN 家族单独签核时有读者（输出口），进了 ExeUnit_7 才因 CSR 不读而变死，两侧对称。
#
# ---- 六条复核判据（跑后在 docs/lanes/exublock0_prereg.md 对账里逐条落数）----
#   (1) 精确绑定：开 vmucp 后 unread 只剩 (a) 258 个 ref-only（= dead_ref 声明逐条相等）；
#   (2) 双射：(b) 28 对 ref 28 <-> impl 28，一对一；
#   (3) 真比较：passing 恰好 30245 + 28 = 30273；
#   (4) 全零：failing / unverified / aborted / unmatched 0；
#   (5) 无 dont_verify、无 elab147、无放宽 appvar、无黑盒；
#   (6) 本文件与钉点文件进 sidecar/script_closure.list，receipt 记 sha256。

fm_target_vmucp_allow
