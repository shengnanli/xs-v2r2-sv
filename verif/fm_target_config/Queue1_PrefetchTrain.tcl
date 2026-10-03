# vmucp 白名单条目：Queue1_PrefetchTrain
#
# 契约见 verif/fm_target_config/README.md：只许注释、fm_target_vmucp_allow、
# fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
#   unread 全部是 ram 中 deq 侧无读者的死存储位，两侧同死、matched_nc：
#       ref  r:/WORK/Queue1_PrefetchTrain/ram_reg[94..98]      （5 位）
#       impl i:/WORK/Queue1_PrefetchTrain/u_core/ram_reg[94..98]
#   成因是 golden 自己的死位：104 位 ram 字高 5 位是 hit/prefetched/pfsource
#   字段，deq 口没有对应输出（firtool 留了存储删了输出），无读者。可读核
#   照抄 golden 保留（删掉反而造成 golden-only 死位、不对称）。
#   双射核对：unread_points.txt 5 行全部 matched_nc，ref/impl 位索引集合
#   完全相同（94..98），非 matched_nc 项为 0。
#   ★复核判据★：unread 5 -> 0，且 passing 恰好 +5（201 -> 206）。
#   passing 不增即空转，不算过。

fm_target_vmucp_allow
