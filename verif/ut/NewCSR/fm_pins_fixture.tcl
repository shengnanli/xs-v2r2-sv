# VARIANTS: NewCSR
# ---------------------------------------------------------------------------
# verif/ut/NewCSR/fm_pins.tcl 的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# NewCSR 的钉点文件是 InterruptFilter 钉点文件加一层 NewCSR/intrMod/ 前缀；孤儿集合也相同：
# miprios 第 0/1/2/5/6/7 组 idx/prioNum[0..5]+enable+isZero（14×6=84）+ 第 4 组 idx[4]，共 85 对。
#   ref  r:/WORK/NewCSR/intrMod/mipriosReg_<g>_<field>_reg[<b>]
#   impl i:/WORK/NewCSR/intrMod/u_core/mipriosReg_<field>_reg[<g>][<b>]
# 照 InterruptFilter 夹具的结构写（不是从日志抄表）；与签核跑 evidence/814fe410e15a/NewCSR/fm.log
# 的 85 条 "Set a match" 回显逐条比对过，顺序与内容完全相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    set R "r:/WORK/$top/intrMod" ; set I "i:/WORK/$top/intrMod/u_core"
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
