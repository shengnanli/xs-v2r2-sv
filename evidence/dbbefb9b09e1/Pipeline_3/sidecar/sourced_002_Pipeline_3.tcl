# vmucp 白名单条目：Pipeline_3（utility.Pipeline 单态化，agent/csr-l2-leaves lane）
#
# 契约见 verif/fm_target_config/README.md：只许注释、fm_target_vmucp_allow、
# fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（首跑 evidence/2f9bb8a2b814/Pipeline_3，signoff-strict，vmucp 关）----
#   native SUCCEEDED / passing 13 / failing 0 / unmatched 0，unread 86 -> strict 判 PARTIAL。
#   unread 全部是 child 深度 1 队列（stages_0）ram 中 deq 侧无读者的死存储位，两侧同死、matched_nc：
#       ref  r:/WORK/Pipeline_3/stages_0/ram_reg[0..85]            （86 位）
#       impl i:/WORK/Pipeline_3/stages_0/u_core/ram_reg[0..85]
#   成因是 golden child 自己的死位：tag/set/vaddr（91 位 ram 字低 86 位） 字段在 deq 口没有输出（firtool 留了存储删了输出）。
#   与 child 独立签核时完全同一组点（verif/fm_target_config/Queue1_PrefetchResp.tcl），
#   本壳 0 行逻辑，只是把同一个 child 原样例化一次。
#   双射核对（机械）：unread_points.txt 86 行全部 matched_nc，ref/impl 位索引集合完全相同（0..85），
#   非 matched_nc 项为 0。
#   ★复核判据★：unread 86 -> 0，且 passing 恰好 +86（13 -> 99，= 跑前登记 expected）。
#   passing 不增即空转，不算过。无 dont_verify、无新黑盒。

fm_target_vmucp_allow
