# vmucp 白名单条目：TLBFA_3
#
# 本文件 = TLBFA_3 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   TLBFA / TLBFA_1 / TLBFA_2 / TLBFA_3(2026-09-17 加):
#          unread 全部是 **reqVpn 的高 11 位(bit37..27) x PORTS**，两侧同死：
#              ref  r:/WORK/<top>/reqVpn[_N]_reg[27..37]
#              impl i:/WORK/<top>/u_core/g_port[N].req_vpn_q_reg[27..37]
#          成因是 golden 自己的死位：reqVpn(=RegNext(vpn)) 的**唯一**读出点是
#          genPPN，而 genPPN 最高只取 vpn[26:18]（三段 9 位）；golden 对 reqVpn
#          的全部切片实测就是 [26:18]/[17:9]/[8:0]/[3:0]/[2:0]，bit37..27 无读者。
#          ★反直觉但重要★：把可读核的 req_vpn_q "优化"成 27 位反而更糟 ——
#          那 11xPORTS 位会变成 golden-only 死位（不对称，连双射都没有）。
#          照抄 golden 的宽度才是对的。四个变体都用脚本核过是精确双射
#          （ref 唯一点数 == impl 唯一点数 == 11 x PORTS，键集合完全相同，
#          位索引恒为 27..37、端口恒为 0..PORTS-1，非 matched_nc 项为 0）。
#          unread 数 33/44/22/22 => PORTS 3/4/2/2。
#          ★复核判据★: unread 归 0，**且** passing 恰好
#              8149 -> 8182(+33) / 8619 -> 8663(+44) /
#              8211 -> 8233(+22) / 8207 -> 8229(+22)；
#          passing 不增即空转，不算过。
#          ★实测：只开 vmucp 是空转，必须配 verif/ut/TLBFA/fm_pins.tcl★
#          白名单落地后先只开 vmucp 跑了一轮（513cda8，官方 runner、receipt 齐全）：
#          passing 8149 **一点没增**、unread 仍 33(33)，判定仍 PARTIAL。
#          原因是 verify_matched_unread 只作用于 **matched** unread 点，而这 33 个
#          FM 自己从没配上过（auto_match_flattened_arrays 读的是
#          report_unmatched_points 的**默认**报告，默认报告不含 unread 类）。
#          加强没有对象，自然不增。启用 fm_pins.tcl 之后日志里的痕迹是干净的：
#          `8149 Compare points matched previously` + `33 Compare points matched by user`。

fm_target_vmucp_allow
