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
# ★fail-closed（2026-09-20 补；在此之前本文件**通篇只有 puts，没有任何中止路径**）★
#   set_user_match **从不抛 Tcl 异常**：名字存在返回 1；名字不存在返回 0 并往
#   fm.log 写一行行首 `Error:`。所以"钉满 N 个"这种自报数字什么都不证明，而旧版
#   连自报都没拿去比 —— 一个点都没配上也照样跑完、照样绿。现在四道守卫：
#     (1) 每一次 set_user_match 都必须返回 1，否则 error；
#     (2) 两侧未匹配未读点必须**全部**是这两族（ref_odd / impl_odd 必须为 0），
#         出现别的形状说明情况变了 —— 停下来诊断，不要盲钉；
#     (3) impl 侧不许有落单的（left 必须为 0）—— 双射；
#     (4) 配对数必须等于**声明出来的字面整数**期望值（每变体一个，见 switch）。
#   终局判据仍在下游、也仍然更强：fm.log 行首 `Error:` 计数（按本文件打的
#   NCBQ_PIN_BEGIN/END 区间归因，scripts/check_pin_errors.py --marker NCBQ_PIN）
#   + Unmatched 比较点与 unread 均 0(0) + 终判 SUCCEEDED。
#
# ★期望钉点数是机械推导的，不是抄来的数字★（本 lane 从 G1 golden 现数）：
#   每槽 23 位 = ReturnNID 11 位（`reg [10:0]`）+ ReturnTxnID 12 位（`reg [11:0]`）；
#   槽数 = golden 里 `reg [10:0] regQueue_<i>_bits_info_ReturnNID;` 的条数。复算：
#     grep -cE '^\s*reg\s+\[10:0\] regQueue_[0-9]+_bits_info_ReturnNID;' <变体>.sv
#       NCBTransactionQueue   -> 64  ⇒ 64 × 23 = 1472
#       NCBTransactionQueue_1 -> 32  ⇒ 32 × 23 =  736
#   ★注意变体与槽数的对应是**现数出来的**：无后缀那个是 64 槽、`_1` 才是 32 槽，
#     与 fm_eq.tcl 注释里"736 / 1472"的行文顺序相反，不要照抄那个顺序。
#   死因复核：golden 里这两个字段除声明与 `ifndef SYNTHESIS 的随机化初值外
#   没有任何读者（四个 infoRead 读口的 ParallelMux 只有 38 位 {QoS,TgtID,SrcID,TxnID}）。
#
# ★中止一律用 `error`，不用 `exit`★（本 lane 实测）：本文件在 sidecar 下跑在
# `interp create -safe` 的受限子解释器里，而 **Tcl safe interp 隐藏 `exit`**：
#     $i eval {info commands exit}  -> ★空（命令不存在）★
#     $i eval {exit 3}              -> 抛出: invalid command name "exit"
#     $i eval {error "PIN_MISS"}    -> 抛出: PIN_MISS

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

    set _refs [report_unmatched_points -reference -status unread -list]
    if {[llength $_refs] == 0} {
        puts "NCBQ_PIN_ERROR: no reference unread points at all -- expected 23 bits x SLOTS dead info bits"
        error "NCBQ_PIN_NO_REF"
    }
    if {![regexp {^r:/WORK/([^/]+)/} [lindex $_refs 0] -> design]} {
        puts "NCBQ_PIN_ERROR: cannot read design name out of [lindex $_refs 0]"
        error "NCBQ_PIN_NO_DESIGN"
    }
    # 期望配对数（推导见文件头）：每槽 23 位 × 槽数。
    switch -exact -- $design {
        NCBTransactionQueue   { set expect 1472 }
        NCBTransactionQueue_1 { set expect 736 }
        default               { set expect -1 }
    }
    if {$expect < 0} {
        puts "NCBQ_PIN_ERROR: unknown variant $design -- record its expected pin count first"
        error "NCBQ_PIN_UNKNOWN_VARIANT=$design"
    }
    # ★标记★：fm.log 里 NCBQ_PIN_BEGIN 与 NCBQ_PIN_END 之间的行首 `Error:` 才是
    #   **本文件**钉点失败（scripts/check_pin_errors.py --marker NCBQ_PIN）。
    puts "NCBQ_PIN_BEGIN $design expect=$expect"

    # ref 侧：regQueue_<槽>_bits_info_Return{NID,TxnID}_reg[<位>]
    set paired 0
    set ref_odd 0
    foreach p $_refs {
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
        # ★用返回值判成败，不用 catch★：set_user_match 从不抛异常（见文件头），
        # catch 版的中止路径永远走不到，计数也就恒等于总数。
        if {![set_user_match $p $impl_lut($i,$f,$b)]} {
            puts "NCBQ_PIN_FAIL: set_user_match returned 0 for $p"
            error "NCBQ_PIN_MISS=$p"
        }
        unset impl_lut($i,$f,$b)
        incr paired
    }

    set left [llength [array names impl_lut]]
    puts "NCBQ_PIN_END $design n=$paired miss=0 expect=$expect"
    puts "NCBQ_PIN_SUMMARY: paired=$paired ref_unhandled=$ref_odd impl_unhandled=$impl_odd impl_left=$left"
    # fail-closed 四道，全在最后一次 set_user_match **之后**（返回值那道在循环里）：
    if {$impl_odd != 0} { error "NCBQ_PIN_UNEXPECTED_IMPL=$impl_odd" }
    if {$ref_odd != 0} { error "NCBQ_PIN_UNEXPECTED_REF=$ref_odd" }
    if {$left != 0} { error "NCBQ_PIN_IMPL_LEFTOVER=$left" }
    if {$paired != $expect} { error "NCBQ_PIN_COUNT=$paired expect=$expect" }
}

ncbq_pin_symmetric_dead_info
