# fm_pins.tcl —— NCBTransactionQueue 家族：把两侧**对称的死寄存器**一一钉起来。
#
# 为什么需要它（实测，不是猜）：
#   strict 首跑 native SUCCEEDED / passing 6007 / failing 0 / unmatched compare points
#   0(0)，唯一卡点是 `736(736) Unmatched reference(implementation) unread points`。
#   736 = 32 槽 × 23 位，内容**全部**是 info.ReturnNID(11 位) 与 info.ReturnTxnID(12 位)
#   —— golden 里这两个字段存了却没有任何读者（四个 infoRead 读口的 ParallelMux 只有
#   38 位 {QoS,TgtID,SrcID,TxnID}），impl 照抄了同一结构，于是两侧**同为死位**。
#   64 槽变体同理，736 → 1472（64 × 23）。
#
#   FM 不会自己把未读点配对（既没有名字同构也没有签名可比），所以这里按
#   「槽号 + 字段 + 位号」三元组显式 1:1 钉。钉完它们变成 matched-not-compared，
#   再由 scripts/fm_eq.tcl 的 verify_matched_unread 加强真正去比（加强不是放宽：
#   passing 必须随之增加 736 / 1472，不增就是空转）。
#
#   ★配对是按构造双射的★：ref 侧 regQueue_<i>_bits_info_Return{NID,TxnID}_reg[<b>]
#   与 impl 侧 u_core/info_q_reg[<i>]\[return_{nid,txn_id}][<b>] 是同一个 Chisel
#   字段的两种展平写法，槽号与位号逐位对应，没有任何人工选择的余地。
#
# ★判据不是「钉满 N 个」★（本轮实测：set_user_match 对不存在的名字不报错、
#   catch 也抓不到，所以计数本身不是 fail-closed）。有效判据是最终 fm.log 里
#   `Error: FM-036` 行数为 0 + `Unmatched ... compare points` 与 unread 均 0(0)
#   + 终判 SUCCEEDED。下面的 puts 只是给人看的诊断。

proc ncbq_pin_symmetric_dead_info {} {

    # impl 侧：u_core/info_q_reg[<槽>]\[<字段>][<位>]
    array set impl_lut {}
    set impl_odd 0
    foreach p [report_unmatched_points -implementation -status unread -list] {
        if {[regexp {info_q_reg\[(\d+)\][^\[]*\[(return_nid|return_txn_id)\]\[(\d+)\]$} \
                 $p -> i f b]} {
            set impl_lut($i,$f,$b) $p
        } else {
            puts "NCBQ_PIN_UNEXPECTED_IMPL: $p"
            incr impl_odd
        }
    }

    # ref 侧：regQueue_<槽>_bits_info_Return{NID,TxnID}_reg[<位>]
    set paired 0
    set ref_odd 0
    foreach p [report_unmatched_points -reference -status unread -list] {
        if {![regexp {regQueue_(\d+)_bits_info_(ReturnNID|ReturnTxnID)_reg\[(\d+)\]$} \
                  $p -> i F b]} {
            puts "NCBQ_PIN_UNEXPECTED_REF: $p"
            incr ref_odd
            continue
        }
        if {$F eq "ReturnNID"} { set f "return_nid" } else { set f "return_txn_id" }
        if {![info exists impl_lut($i,$f,$b)]} {
            puts "NCBQ_PIN_NO_PARTNER: $p"
            incr ref_odd
            continue
        }
        set_user_match $p $impl_lut($i,$f,$b)
        unset impl_lut($i,$f,$b)
        incr paired
    }

    set left [llength [array names impl_lut]]
    puts "NCBQ_PIN_SUMMARY: paired=$paired ref_unhandled=$ref_odd impl_unhandled=$impl_odd impl_left=$left"
}

ncbq_pin_symmetric_dead_info
