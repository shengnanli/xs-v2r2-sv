# VARIANTS: IntRFWBCollideChecker FpRFWBCollideChecker VfRFWBCollideChecker V0RFWBCollideChecker VlRFWBCollideChecker IntRFReadArbiter FpRFReadArbiter VfRFReadArbiter V0RFReadArbiter VlRFReadArbiter
# ---------------------------------------------------------------------------
# DataPathArb 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 变体 = Makefile FM_VARIANTS 的 10 个装配壳。每个 N=1 仲裁器（只有 1 个请求口的
# WBArbiter_* 单态）贡献 5 个对称死位（钉点文件三族）：
#   A  cancelCounter_0_reg[0..2] <-> u_core/cancel_cnt_q_reg[0][0..2]
#   B  hasFull_reg               <-> u_core/has_full_q_reg
#   C  isFull_0_reg              <-> u_core/is_full_q_reg[0]
#   ref  r:/WORK/<top>/arbiters_<k>/...   impl i:/WORK/<top>/arbiters_<k>/u_core/...
#
# 下表"哪些 arbiters_<k> 是 N=1"是从 G1 golden 机械数出来的（与钉点文件 _n1_arbs 的
# 计数同源，这里多给出了下标）：<top>.sv 里 `WBArbiter* arbiters_<k> (` 的模块，
# 若声明了 `reg ... cancelCounter_0;` 而没有 cancelCounter_1，就是 N=1。复算：
#   for m,k in `grep -oE '^\s*WBArbiter[0-9_]*\s+arbiters_[0-9]+' <top>.sv`:
#     grep -q 'reg .*cancelCounter_0;' $m.sv && ! grep -q 'cancelCounter_1;' $m.sv && echo k
# 钉点文件对两侧列表先 lsort -unique，所以本夹具的列表顺序不影响调用序列。
# 逐条核过真实 fm.log：evidence/833a201786eb/<top>/fm.log 十个变体的 "Set a match"
# 回显（合计 175 条）与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc _fx_dparb_n1 {} {
    global top
    switch -exact -- $top {
        IntRFWBCollideChecker { return {3 5 6 7} }
        FpRFWBCollideChecker  { return {5} }
        VfRFWBCollideChecker  { return {1 4 5} }
        V0RFWBCollideChecker  { return {1 4 5} }
        VlRFWBCollideChecker  { return {0 1 2 3} }
        IntRFReadArbiter      { return {8 9 10} }
        FpRFReadArbiter       { return {0 1 3 4 6 7 10} }
        VfRFReadArbiter       { return {6 7 8 9 10 11} }
        V0RFReadArbiter       { return {2 3} }
        VlRFReadArbiter       { return {2 3} }
    }
    error "DataPathArb fixture: unknown variant $top"
}
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    foreach k [_fx_dparb_n1] {
        set rs "r:/WORK/$top/arbiters_$k"
        set is "i:/WORK/$top/arbiters_$k/u_core"
        for {set b 0} {$b < 3} {incr b} {
            lappend ref  "$rs/cancelCounter_0_reg\[$b\]"
            lappend impl "$is/cancel_cnt_q_reg\[0\]\[$b\]"
        }
        lappend ref  "$rs/hasFull_reg"   ; lappend impl "$is/has_full_q_reg"
        lappend ref  "$rs/isFull_0_reg"  ; lappend impl "$is/is_full_q_reg\[0\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
