# VARIANTS: RenameBuffer
# ---------------------------------------------------------------------------
# RenameBuffer 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 51 个点，三族，机械推导自 G1 golden 的寄存器声明：
#   A  5 点  reg deqPtrVec_<i>_flag;            i=1..5
#   B 40 点  reg [7:0] deqPtrVec_<i>_value;     i=1..5
#   C  6 点  reg [7:0] io_toVecExcpMod_logicPhyRegMap_<j>_bits_preg_r;  j=0..5 的 bit7
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    for {set i 1} {$i <= 5} {incr i} {
        lappend ref  "r:/WORK/$top/deqPtrVec_${i}_flag_reg"
        lappend impl "i:/WORK/$top/u_core/deq_ptr_flag_q_reg\[$i\]"
        for {set b 0} {$b < 8} {incr b} {
            lappend ref  "r:/WORK/$top/deqPtrVec_${i}_value_reg\[$b\]"
            lappend impl "i:/WORK/$top/u_core/deq_ptr_value_q_reg\[$i\]\[$b\]"
        }
    }
    for {set j 0} {$j < 6} {incr j} {
        lappend ref  "r:/WORK/$top/io_toVecExcpMod_logicPhyRegMap_${j}_bits_preg_r_reg\[7\]"
        lappend impl "i:/WORK/$top/u_core/vec_excp_preg_q_reg\[$j\]\[7\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
