# vmucp 白名单条目：DuplicatedTagArray
#
# 本文件 = DuplicatedTagArray 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
# 原条目进白名单时没有把依据写进 fm_eq.tcl（拆分时如实记录）；依据可到 git log 里找：
# `git log -SDuplicatedTagArray -- scripts/fm_eq.tcl`。
#
# ---- 2026-09-28 dcache lane 重签时的实测依据（impl 子模块全部换成重写件之后）----
#   基线（vmucp 关、merge_dup 关，assembly，非正式试跑，commit 21c819c3）：
#     native SUCCEEDED / passing 2450 / failing 0 / unmatched compare points 0 / 黑盒 16（array_8_ext 两侧各 8）
#     unread = 10 个 matched_nc + 8 个 impl 独有：
#       · matched_nc：r:/WORK/DuplicatedTagArray/mbistPl/addrReg_reg[0..8] 与 addrRdReg_reg[8]
#           <-> i:/WORK/DuplicatedTagArray/mbistPl/u_core/<同名>，两侧同名同位
#         （MbistPipeDcacheTag 叶子节点的 MBIST 地址打拍寄存器，经 toSRAM_*_addr / addr_rd 送进
#           SRAMTemplate_116 后在下游没有读者——FM 在两侧都判 unread、同名同位配上；
#           ref 侧下游就是 golden SRAMTemplate_116，所以这是 golden 自身的死位，不是重写引入的）。
#       · impl 独有 8 个：xs_SRAMTemplate_core 的 rdata_last_REG（holdRead 关时与 respReg 同方程），
#         merge_dup 开（工具默认，与 SRAMTemplate_* 自身签核同口径）后被合并，不再出现。
#   vmucp 开 + merge_dup 默认：passing 2460（= 2450 + 10，正好是那 10 个 matched_nc），
#   unread 0、unmatched 0、黑盒仍只有 16 个 array_8_ext。
# ---- 六条证据 ----
#   (1) 精确绑定：matched_nc 集合 = 上述 10 位。(2) 双射：10 ref <-> 10 impl，独占 0。
#   (3) 真比较：passing +10。(4) 全零：failing / unverified / aborted / unmatched 全 0。
#   (5) 无放宽：无 dont_verify / elab147 / relaxed appvar；黑盒只有审定过的厂商叶子 array_8_ext。
#   (6) 摘要：本文件进 sidecar/script_closure.list，receipt 记其 sha256。
#   复核判据：passing 2460、unread 0、unmatched 全零、bbox_objects 16。

fm_target_vmucp_allow
