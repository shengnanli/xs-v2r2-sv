# VARIANTS: DecodeStage
# ---------------------------------------------------------------------------
# DecodeStage 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 2 个点（钉点文件 _expect=2）：golden 的两个 perf 探针打拍寄存器两侧都无读者
#   r:/WORK/DecodeStage/last_REG_reg   <-> i:/WORK/DecodeStage/u_core/frontendStall_probe_q_reg
#   r:/WORK/DecodeStage/last_REG_1_reg <-> i:/WORK/DecodeStage/u_core/backendStall_probe_q_reg
# 钉点文件**不**对 ref 列表排序，调用序列直接跟着 FM 的返回顺序走；真实 FM 返回的是
# 按名字 ASCII 序（last_REG_1_reg 在 last_REG_reg 之前），所以本夹具用 lsort 复现它。
# 逐条核过真实 fm.log：evidence/{e1cca4696c04,772003f0e63e,fe8b8e8c8332}/DecodeStage/fm.log
# 三轮的 "Set a match" 回显都是这 2 条、同一顺序，与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set pairs [list \
        last_REG_reg   frontendStall_probe_q_reg \
        last_REG_1_reg backendStall_probe_q_reg]
    set ref {} ; set impl {}
    foreach {r i} $pairs {
        lappend ref  "r:/WORK/$top/$r"
        lappend impl "i:/WORK/$top/u_core/$i"
    }
    if {[lindex $args 0] eq "-reference"} { return [lsort $ref] }
    return [lsort $impl]
}
