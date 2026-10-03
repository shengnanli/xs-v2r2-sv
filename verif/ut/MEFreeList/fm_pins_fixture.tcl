# VARIANTS: MEFreeList
# ---------------------------------------------------------------------------
# MEFreeList 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 530 个点 = MEFreeList 的 debug 影子寄存器四族（钉点文件 _expect=530），两侧对称死位：
#   debugArchRAT_<i>_reg[<b>]       <-> debugArchRAT_reg[<i>][<b>]       i=0..31 b=0..7  256
#   debugArchRAT_REG_<i>_reg[<b>]   <-> debugArchRAT_REG_reg[<i>][<b>]   i=0..31 b=0..7  256
#   debugArchHeadPtr{,_REG}_flag_reg                     （同名）              2
#   debugArchHeadPtr{,_REG}_value_reg[<b>]               （同名）  b=0..7     16
# 数量机械推导自 G1 golden MEFreeList.sv：
#   grep -cE '^\s*reg\s+\[7:0\]\s+debugArchRAT_[0-9]+;'     -> 32
#   grep -cE '^\s*reg\s+\[7:0\]\s+debugArchRAT_REG_[0-9]+;' -> 32
#   debugArchHeadPtr{,_REG}_{flag,value[7:0]}                -> 2 × 9
# 钉点文件**不**对 ref 列表排序，调用序列跟着 FM 的返回顺序走；真实 FM 返回的是
# 按名字 ASCII 序（实测：fm.log 回显的 ref 序列 == 它自己的 lsort），本夹具用 lsort 复现。
# 逐条核过真实 fm.log：evidence/361e2ab086bf/MEFreeList/fm.log 的 530 条 "Set a match" 回显与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set R "r:/WORK/$top"
    set I "i:/WORK/$top/u_core"
    set ref {} ; set impl {}
    foreach stem {debugArchRAT debugArchRAT_REG} {
        for {set i 0} {$i < 32} {incr i} {
            for {set b 0} {$b < 8} {incr b} {
                lappend ref  "$R/${stem}_${i}_reg\[$b\]"
                lappend impl "$I/${stem}_reg\[$i\]\[$b\]"
            }
        }
    }
    foreach hp {debugArchHeadPtr debugArchHeadPtr_REG} {
        lappend ref  "$R/${hp}_flag_reg"
        lappend impl "$I/${hp}_flag_reg"
        for {set b 0} {$b < 8} {incr b} {
            lappend ref  "$R/${hp}_value_reg\[$b\]"
            lappend impl "$I/${hp}_value_reg\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return [lsort $ref] }
    return [lsort $impl]
}
