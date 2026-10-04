# vmucp 白名单条目：ITTageTable
#
# 本文件 = ITTageTable 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
# ITTageTable{,_1,_2,_3,_4} 加入依据(2026-09-14, agent/ittage 实测)：5 个目标 strict
# 首跑均 native SUCCEEDED / failing 0 / unmatched 0，只剩 unread 卡住。unread 点
# 在各自 verif/ut/*/fm_pins.tcl 钉完后**全部**是 matched_nc，ref 侧唯一点数 ==
# impl 侧唯一点数、非 matched_nc 项为 0，严格双射。内容两类，均为两侧同为死位：
#  (a) MBIST 地址 9 位——golden MbistPipeIttage* 的 addrReg[7:0](写地址整条)与
#      addrRdReg[7]，对可读核的 addr_q[7:0] / addr_rd_q[7]。死因：SRAMTemplate_76/78
#      里 mbistBd_addr 定义后全文再无引用，mbistBd_addr_rd 只用 [6:0]（厂商宏
#      array_6_ext 的 RW0_addr 仅 7 位 / 深度 128）。
#  (b) 每个 SRAM bank 一个 array_6_ext/reg_RW0_ren——两侧同名同路径(同一份 golden
#      厂商宏一起 elaborate)，FM 自己就配上了；死因见 array_6_ext.v：reg_RW0_ren
#      只在 `ifdef RANDOMIZE_GARBAGE_ASSIGN 分支被读，综合视图走 `else 分支。

fm_target_vmucp_allow
