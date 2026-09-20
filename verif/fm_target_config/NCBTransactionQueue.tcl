# vmucp 白名单条目：NCBTransactionQueue
#
# 本文件 = NCBTransactionQueue 这一个目标的 per-target 证明数据。
# 契约见 verif/fm_target_config/README.md：只许出现注释、fm_target_vmucp_allow、
# fm_target_appvar 三种东西；scripts/fm_eq.tcl 只 source 与 FM_TOP 同名的这一份。
#
# ---- 加入依据（原样搬自 scripts/fm_eq.tcl，未改一字）----
#   NCBTransactionQueue{,_1}(2026-09-17 加): 内容是 info.ReturnNID(11 位) +
#          info.ReturnTxnID(12 位) = 23 位/槽，两侧同为死位 —— golden 存了这两个
#          字段，但四个 infoRead 读口的 ParallelMux 只有 38 位
#          {QoS,TgtID,SrcID,TxnID}，可读核照抄同一结构。非 Return* 的 unread 点 0 个。
#          ★注意这一族的基线不是 matched_nc 而是 unmatched unread★
#          ★逐个变体点名，不许按行文顺序推★：
#              NCBTransactionQueue    槽号 0..63 = 64 槽 x 23 位 = **1472**(1472)
#              NCBTransactionQueue_1  槽号 0..31 = 32 槽 x 23 位 = ** 736**( 736)
#          （本行原先写作 "(736(736) / 1472(1472))"，照行文顺序会以为无后缀是 32 槽，
#            ★现数是反的★。agent/pindebt 在重算期望值时发现，集成者自己数
#            golden 的 regQueue_<i>_bits_info_ReturnNID 槽号最大值复核：63 / 31。
#            照抄那个顺序会把两个变体的期望值装反，而装反之后**两边都是正数、
#            都"有个期望值"，闸不会响** —— 只有真去数槽位才暴露。）
#          FM 自己配不上(既非名字同构、常数间也无签名可比)，
#          所以光开本加强不够，必须先配对。配对在模块本地
#          verif/ut/NCBTransactionQueue/fm_pins.tcl，按「槽号+字段+位号」三元组从
#          report_unmatched_points -status unread -list 两侧现场发现后 1:1 钉：
#              ref  regQueue_<i>_bits_info_Return{NID,TxnID}_reg[<b>]
#              impl u_core/info_q_reg[<i>]\[return_{nid,txn_id}][<b>]
#          钉后实测 unmatched unread 归 0(0)、日志里没有 `^ *Error:` 行
#          (钉点计数本身不 fail-closed, set_user_match 对不存在的名字不报错,
#          有效判据是这两条 + 终判 SUCCEEDED)。
#
#          ★复核判据★: passing 6007 -> 6743(_1, +736) / 12054 -> 13526(+1472)、
#          failing 仍 0、unread 归 0。

fm_target_vmucp_allow
