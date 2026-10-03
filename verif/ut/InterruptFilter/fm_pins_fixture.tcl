# VARIANTS: InterruptFilter
# ---------------------------------------------------------------------------
# InterruptFilter 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 本钉点文件读的是 report_unmatched_points 的**默认**报告（不带 -status unread），
# 两侧各 85 个孤儿 compare point（钉点文件头【本文件解决什么】，第二跑实测 85(85)）：
#   miprios 第 0/1/2/5/6/7 组：idx[0..5] + prioNum[0..5] + enable + isZero = 14 × 6 = 84
#   miprios 第 4 组：只有 idx[4] 一位                                         =  1
#   ref  r:/WORK/InterruptFilter/mipriosReg_<g>_<field>_reg[<b>]   （1 位字段无 [b]）
#   impl i:/WORK/InterruptFilter/u_core/mipriosReg_<field>_reg[<g>][<b>]  （1 位字段只有 [g]）
# ★这 85 点不是能从结构推出来的"全部"★（钉点文件的结构上界是 378）：哪些常零寄存器
# 被 FM 签名分析配不上是实测量，所以本表照**真实 FM 的返回集合**写（第 4 组只剩 idx[4]
# 就是这样来的）。夹具的职责是把钉点文件的输入固定成它在签核跑里实际看到的那一份。
# 钉点文件按 (族,组,字段,位) key 的 lsort 顺序发调用，本夹具的列表顺序不影响序列。
# 逐条核过真实 fm.log：evidence/{3e3ea3700d11,5254ac5bde44,b3808b860b38,e8d0f728dda2}/
# InterruptFilter/fm.log 四轮的 85 条 "Set a match" 回显完全相同，且与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    set R "r:/WORK/$top" ; set I "i:/WORK/$top/u_core"
    foreach g {0 1 2 5 6 7} {
        foreach fld {idx prioNum} {
            for {set b 0} {$b < 6} {incr b} {
                lappend ref  "$R/mipriosReg_${g}_${fld}_reg\[$b\]"
                lappend impl "$I/mipriosReg_${fld}_reg\[$g\]\[$b\]"
            }
        }
        foreach fld {enable isZero} {
            lappend ref  "$R/mipriosReg_${g}_${fld}_reg"
            lappend impl "$I/mipriosReg_${fld}_reg\[$g\]"
        }
    }
    lappend ref  "$R/mipriosReg_4_idx_reg\[4\]"
    lappend impl "$I/mipriosReg_idx_reg\[4\]\[4\]"
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
