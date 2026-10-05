# vmucp 白名单条目：ExuBlock（exublock0 lane，整数执行块）
#
# 本文件 = ExuBlock 这一个目标的 per-target 证明数据。契约见 verif/fm_target_config/README.md：
# 只许出现注释、fm_target_vmucp_allow、fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（诊断跑 diagnostic-full，关 vmucp、merge_dup 关，@28d32f0d1，未出证）----
# native SUCCEEDED / passing 52729 / failing 0 / unmatched compare 0 / constant_reg 1985；
# unread：ref-only 266、impl-only 8、matched_nc 74：
#   (a) ref-only 258 = verif/dead_ref/ExuBlock.json（exus_7 的 CSR 190 + Fence 68，继承 ExeUnit_7 的 PASS_DEAD_REF）—— 不在本白名单；
#   (b) 两侧同死、本白名单管的 82 对，全部是 child 单独签核时已入白名单的那些，本层无新增：
#       exus / exus_2（ExeUnit）各 27 对 —— 同 verif/fm_target_config/ExeUnit.tcl（Bku 20 + Mul 7）；
#       exus_7（ExeUnit_7）28 对 —— 同 verif/fm_target_config/ExeUnit_7.tcl（Div 6 + DelayN_214 22；其中 DelayN_214 第 2 级
#         gpaddr[63:56] 8 对在这次诊断跑里还是 ref 8 / impl 8 unmatched unread —— 那时 ExeUnit_7 的钉点还没补这 8 对；
#         本层的 fm_pins_pre.tcl 继承了补过的 ExeUnit_7 钉点）。
#   本层 frm / io_error 打拍寄存器都有读者，不在 unread 里。
#
# ---- 六条复核判据（跑后在 docs/lanes/exublock0_prereg.md 对账里逐条落数）----
#   (1) 精确绑定：开 vmucp 后 unread 只剩 (a) 258 个 ref-only（= dead_ref 声明逐条相等）；
#   (2) 双射：(b) 82 对一对一；
#   (3) 真比较：passing 恰好 52729 + 82 = 52811；
#   (4) 全零：failing / unverified / aborted / unmatched 0；
#   (5) 无 dont_verify、无 elab147、无放宽 appvar、无黑盒；
#   (6) 本文件与钉点文件进 sidecar/script_closure.list，receipt 记 sha256。

fm_target_vmucp_allow
