# =============================================================================
# DataPathArb「匹配后」钉点：把 N=1 WBArbiter 里 golden 与重写核**同为死位**的未读寄存器一一配对。
# 由 ut_common.mk 作为 FM_PIN_TCL 传入（首次 match 之后执行）。10 个目标共用本文件。
#
# 为什么需要（lane 内非正式试跑实测，不是推测）
# ------------------------------------------------
# VlRFWBCollideChecker（4 个仲裁器全是 WBArbiter_3，N=1）试跑：native SUCCEEDED、failing 0、
# 比较点 unmatched 0(0)，但 **20(20) 个 unmatched unread 点** = 4 个实例 × 5 位：
#     ref  r:/WORK/<top>/arbiters_<m>/cancelCounter_0_reg[0..2] / hasFull_reg / isFull_0_reg
#     impl i:/WORK/<top>/arbiters_<m>/u_core/cancel_cnt_q_reg[0][0..2] / has_full_q_reg / is_full_q_reg[0]
# 这 5 位是 N=1 仲裁器的反饥饿状态：只有一路 ⇒ 永远是最高优先级 ⇒ ready 恒 1 ⇒ 计数器永不自增、
# isFull/hasFull 永不置位 —— **golden 自己的死逻辑**，重写核照抄（rtl/backend/WBArbiter.sv 不因 N=1 裁剪），
# 于是两侧对称死、没人读。WBArbiter_3 等单独签核时已有同一结论（verif/ut/WBArbiterVariants/fm_pins.tcl，
# scripts/wbarbiter_reachability.py 穷举 N=1 可达状态只有全 0）。
# 两侧词干不同（cancelCounter_0 vs cancel_cnt_q[0]），fm_eq.tcl 的 auto_match_flattened_arrays
# 只看顶层且只读默认报告（不含 unread 类），配不上；单开 vmucp 也会空转（unmatched unread 没有对子可比）。
# 所以先在这里配对，再由 verif/fm_target_config/<top>.tcl 开 vmucp 让 FM 真去比。
#
# ★fail-closed★（与 WBArbiterVariants/fm_pins.tcl 同一套判据）
#   1. 每条 ref 未读点必须命中下面三条结构规则之一，且位于 arbiters_<m>/ 之下、下标 k 只能是 0（N=1）；
#      形状不符即 error（情况变了就停下来诊断，不盲钉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防凭空造点）；
#   3. 同一条 impl 路径不许被钉两次；
#   4. 钉点条数必须等于 impl 侧未读点数（双射）；
#   5. 总数必须 = 5 × 本目标 N=1 仲裁器个数（下表按目标声明的字面整数），且三类各自的计数也对。
# ★用 `error` 不用 `exit`★（受限 safe interp 里没有 exit）。进 fm.log 的字一律 ASCII。
# 顶层名从未读点路径里现取；期望数用 $top 查表（sidecar 把只读的 top 传进 safe interp）。
# =============================================================================

# 每个目标的 N=1 仲裁器个数（golden 实测：scripts/gen_datapath_arb.py 解析的例化表）
set _n1_arbs [dict create \
    IntRFWBCollideChecker 4 \
    FpRFWBCollideChecker  1 \
    VfRFWBCollideChecker  3 \
    V0RFWBCollideChecker  3 \
    VlRFWBCollideChecker  4 \
    IntRFReadArbiter      3 \
    FpRFReadArbiter       7 \
    VfRFReadArbiter       6 \
    V0RFReadArbiter       2 \
    VlRFReadArbiter       2]

if {![dict exists $_n1_arbs $top]} {
    error "DPARB_PIN_ERROR: top $top not in the declared table"
}
set _expect [expr {5 * [dict get $_n1_arbs $top]}]

proc dparb_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        error "DPARB_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [dparb_unread reference]
set _impl [dparb_unread implementation]

set _pinned 0
set _used   {}
set _nA 0 ; set _nB 0 ; set _nC 0
set _arbs {}
foreach r $_ref {
    set i ""
    # A. arbiters_<m>/cancelCounter_0_reg[<b>]  <->  arbiters_<m>/u_core/cancel_cnt_q_reg[0][<b>]
    if {[regexp {^r:(/WORK/[^/]+/arbiters_\d+)/cancelCounter_0_reg\[([0-2])\]$} $r -> scope bit]} {
        set i "i:$scope/u_core/cancel_cnt_q_reg\[0\]\[$bit\]"
        incr _nA
    # B. arbiters_<m>/hasFull_reg  <->  arbiters_<m>/u_core/has_full_q_reg
    } elseif {[regexp {^r:(/WORK/[^/]+/arbiters_\d+)/hasFull_reg$} $r -> scope]} {
        set i "i:$scope/u_core/has_full_q_reg"
        incr _nB
    # C. arbiters_<m>/isFull_0_reg  <->  arbiters_<m>/u_core/is_full_q_reg[0]
    } elseif {[regexp {^r:(/WORK/[^/]+/arbiters_\d+)/isFull_0_reg$} $r -> scope]} {
        set i "i:$scope/u_core/is_full_q_reg\[0\]"
        incr _nC
    } else {
        error "DPARB_PIN_ERROR: unexpected ref unread point $r -- only N=1 arbiter dead state is accepted; stop and diagnose, do NOT blind-pin"
    }
    if {[regexp {^r:/WORK/([^/]+)/} $r -> rtop] && $rtop ne $top} {
        error "DPARB_PIN_ERROR: unread point $r is not under top $top"
    }
    if {[lsearch -exact $_impl $i] < 0} {
        error "DPARB_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
    }
    if {[lsearch -exact $_used $i] >= 0} {
        error "DPARB_PIN_ERROR: impl path pinned twice (over-pinning): $i"
    }
    if {![set_user_match $r $i]} {
        error "DPARB_PIN_ERROR: set_user_match returned 0 for $r <-> $i"
    }
    lappend _used $i
    lappend _arbs $scope
    incr _pinned
}

# 钉完再数：双射 + 总数 + 分类计数都要对
if {$_pinned != [llength $_impl]} {
    error "DPARB_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
}
set _narb [llength [lsort -unique $_arbs]]
if {$_pinned != $_expect} {
    error "DPARB_PIN_ERROR: pinned $_pinned points, expected $_expect (5 x N=1 arbiters of $top)"
}
if {$_nA != 3 * $_narb || $_nB != $_narb || $_nC != $_narb || 5 * $_narb != $_expect} {
    error "DPARB_PIN_ERROR: per-class counts wrong: cancelCounter $_nA hasFull $_nB isFull $_nC over $_narb arbiters"
}
puts "DPARB_PINS: $top pinned $_pinned points over $_narb N=1 arbiters (cancelCounter $_nA, hasFull $_nB, isFull $_nC); bijection ok"
