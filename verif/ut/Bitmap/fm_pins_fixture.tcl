# VARIANTS: Bitmap
# ---------------------------------------------------------------------------
# Bitmap 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 8 个点 = 8 个条目 × id bit3（golden `reg [3:0] entries_<i>_id`，写入恒 {1'h0,id[2:0]}，
# 读者只取 [2:0]）——与钉点文件 _expect=8 同源：
#   ref  r:/WORK/Bitmap/entries_<i>_id_reg[3]
#   impl i:/WORK/Bitmap/u_core/entries_id_reg[<i>][3]          i=0..7
# 实测首跑 unread_ref 8 / unread_impl 8 恰为这 8 位，所以两侧列表里没有别的点。
# 逐条核过真实 fm.log：evidence/46fb5c533f75/Bitmap/fm.log 的 8 条 "Set a match"
# 回显与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    for {set i 0} {$i < 8} {incr i} {
        lappend ref  "r:/WORK/$top/entries_${i}_id_reg\[3\]"
        lappend impl "i:/WORK/$top/u_core/entries_id_reg\[$i\]\[3\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
