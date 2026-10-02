# vmucp 白名单条目：Queue1_PrefetchResp
#
# 契约见 verif/fm_target_config/README.md：只许注释、fm_target_vmucp_allow、
# fm_target_appvar；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据 ----
#   unread 全部是 ram 中 deq 侧无读者的死存储位，两侧同死、matched_nc：
#       ref  r:/WORK/Queue1_PrefetchResp/ram_reg[0..85]      （86 位）
#       impl i:/WORK/Queue1_PrefetchResp/u_core/ram_reg[0..85]
#   成因是 golden 自己的死位：91 位 ram 字 = tag[32:0] + set[41:33] +
#   vaddr[85:42] + pfSource[90:86]，而 deq 口只输出 pfSource（firtool 留了
#   存储删了输出），tag/set/vaddr 共 86 位无任何读者。可读核照抄 golden
#   保留这 86 位（删掉反而造成 golden-only 死位、不对称）。
#   双射核对：unread_points.txt 86 行全部 matched_nc，ref/impl 位索引集合
#   完全相同（0..85），键集合相同，非 matched_nc 项为 0。
#   ★复核判据★：unread 86 -> 0，且 passing 恰好 +86（13 -> 99）。
#   passing 不增即空转，不算过。

fm_target_vmucp_allow
