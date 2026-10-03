# vmucp 白名单条目：OthersEntryVecMem_14
#
# 本文件 = OthersEntryVecMem_14 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# 加入依据（2026-10-03, agent/iq-entry-leaves 实测，首跑 commit cc6120772）：
# OthersEntryVecMem_14 是 EntriesVlduVstu 的 simp 条目（访存向量族，5 源，无 IQ 唤醒）。
# 钉点后（verif/ut/OthersEntryVecMem_14/fm_pins_pre.tcl，1483 对，OE_PIN_END n=1483 miss=0）
# strict 跑 native SUCCEEDED / passing 3919 / failing 0 / unmatched 0 / 黑盒 0，只剩 unread 15 卡住。
# 15 点**全部** matched_nc，ref 侧 15 个唯一点 <-> impl 侧 15 个唯一点，严格双射；
# 这 15 对正是钉点文件自己钉上去的，不是 FM 猜配：
#   ref  entryReg_status_srcStatus_<s>_srcLoadDependency_<q>_reg[1]
#   impl u_entry/r_ld_dep_reg[s][q][1]            (s in 0..4, q in 0..2, 共 15 对)
# 死因两侧同源、结构性的：本族 golden 一个 ldCancel 端口都没有，LoadShouldCancel 整条不生成，
# 影子的 bit[1] 没有读出点；次态是左移(bit1' = bit0)，transEntry 露的是次态，
# 所以寄存器 bit1 是纯写入位 —— 与已在白名单上的 OthersEntry_164/_150/_136（VEC 族 simp）同因同型。
# ★复核判据(跑前预登记)★ 加强后 passing 必须**恰好 +15**：3919 -> 3934
#   （= docs/fm_predictions/OthersEntryVecMem_14.json 的模型值）；unread 归 0、failing 仍 0、unmatched 全 0、
#   无 dont_verify、无新黑盒。passing 不增而 unread 归 0 = 点被吞掉，不算过。

fm_target_vmucp_allow
