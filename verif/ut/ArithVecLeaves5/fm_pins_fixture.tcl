# VARIANTS: Adder_chain_rnd DivUnit FDivSqrt VIAluDecoder VIntAdder64b
# ---------------------------------------------------------------------------
# ArithVecLeaves5 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 变体 = Makefile 的 FM_VARIANTS（=$(LEAVES) 五个叶子）。钉点文件只在 DivUnit 下
# 有动作，其余四个必须发 0 次调用 —— 也登记进基线，防"条件写错让别的叶子也钉"。
#
# DivUnit：6 个对称死位，全在 divDataModule 子层（钉点文件 _expected 表）：
#   aLZCReg_reg[6] / dLZCReg_reg[6] / udNegReg_{0,1,3,4}_reg[67]
#   ref  r:/WORK/DivUnit/divDataModule/<leaf>
#   impl i:/WORK/DivUnit/u_core/u_div/<leaf>
# 两侧列表顺序照真实 FM 的返回顺序（调用序列按 ref 列表顺序发出）。
# 逐条核过真实 fm.log：evidence/786d0b438756/DivUnit/fm.log 的 6 条
# "Set a match" 回显与桩序列逐字节相同；另四个叶子的 fm.log 钉点段 0 条。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    if {$top ne "DivUnit"} {
        error "ArithVecLeaves5 fixture: report_unmatched_points called for $top (pin file should be a no-op there)"
    }
    set ref {} ; set impl {}
    foreach leaf {aLZCReg_reg[6] dLZCReg_reg[6] udNegReg_0_reg[67] udNegReg_1_reg[67]
                  udNegReg_3_reg[67] udNegReg_4_reg[67]} {
        lappend ref  "r:/WORK/$top/divDataModule/$leaf"
        lappend impl "i:/WORK/$top/u_core/u_div/$leaf"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
