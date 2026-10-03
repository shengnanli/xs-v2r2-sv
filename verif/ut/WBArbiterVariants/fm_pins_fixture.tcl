# VARIANTS: WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_3 WBArbiter_30 WBArbiter_33 WBArbiter_38 WBArbiter_52 WBArbiter_55 WBArbiter_58 WBArbiter_64 WBArbiter_65 WBArbiter_66
# ---------------------------------------------------------------------------
# WBArbiterVariants 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 变体 = Makefile 的 $(VARIANTS) 13 个单态。钉点文件的两条分支：
#   N>=2（请求口 >=2）：两侧没有未读点，必须 0 次调用   —— 9 个变体
#   N=1               ：2 个对称死位（钉点文件 _expect_n1=2）—— 4 个变体
#       r:/WORK/<top>/cancelCounter_0_reg[0] <-> i:/WORK/<top>/u_core/cancel_cnt_q_reg[0][0]
#       r:/WORK/<top>/hasFull_reg            <-> i:/WORK/<top>/u_core/has_full_q_reg
# 哪些是 N=1 从 G1 golden 机械数：`grep -cE 'reg .*cancelCounter_[0-9]+;' <top>.sv` == 1
#   -> WBArbiter_3 / WBArbiter_38 / WBArbiter_58 / WBArbiter_66（其余 2..4）。
# （注意：同一单态在 DataPathArb 装配壳里作 child 时 FM 报的是 5 个点 —— 那是另一份
#   钉点文件、另一张夹具；单测顶层下实测就是这 2 个。）
# 逐条核过真实 fm.log：evidence/173b0ea3d073/<top>/fm.log 13 个变体，N=1 的 4 个
# 各 2 条 "Set a match" 回显、其余 0 条，与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    if {[lsearch -exact {WBArbiter_3 WBArbiter_38 WBArbiter_58 WBArbiter_66} $top] >= 0} {
        lappend ref  "r:/WORK/$top/cancelCounter_0_reg\[0\]"
        lappend impl "i:/WORK/$top/u_core/cancel_cnt_q_reg\[0\]\[0\]"
        lappend ref  "r:/WORK/$top/hasFull_reg"
        lappend impl "i:/WORK/$top/u_core/has_full_q_reg"
    } elseif {[lsearch -exact {WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_30 WBArbiter_33
                               WBArbiter_52 WBArbiter_55 WBArbiter_64 WBArbiter_65} $top] < 0} {
        error "WBArbiterVariants fixture: unknown variant $top"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
