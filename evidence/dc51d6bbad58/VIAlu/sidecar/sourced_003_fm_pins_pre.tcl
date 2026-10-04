# =============================================================================
# fm_pins_pre.tcl —— VIAlu「匹配前」钉点（只 set_user_match，不约束 ref）
#
# 要消的名差只在归约子单元（vReduAlu = Reduction）里：与它自签核同一套（verif/ut/Reduction/fm_pins_pre.tcl，
#   golden 顶层 33 个寄存器共 817 位，重写核同名、只多一层 u_core），只把前缀换成本层实例路径：
#     ref  r:/WORK/VIAlu/vReduAlu/<reg>_reg[b]   <->   impl i:/WORK/VIAlu/u_core/vReduAlu/u_core/<reg>_reg[b]
#   为什么全钉而不只钉死位：vdType_reg_s1[3:2] 两侧同为无读者死位，签名匹配配不上；其余寄存器一并钉，配对不依赖签名分析。
#   掩码子单元（vMaskAlu = VMask）自签核时 FM 按名字配上（无钉点），本层不钉；本层自己的 5 个寄存器与 golden 同名，不钉。
# 用 -type cell：钉的是 DFF 单元。fail-closed：逐条数返回值；拒一条或总数 != 817 就 error。进 fm.log 的输出全 ASCII。
# =============================================================================
proc _vialu_redu_pin_pre { } {
    set top $::top
    if {$top ne "VIAlu"} { error "VIALU_PIN_UNKNOWN_TOP=$top" }
    set regs {
        fire_reg_s1 1  old_vd_reg_s1 128  ta_reg_s1 1  vl_reg_s1 8  vd_vsew_reg_s1 2
        eewVs2_reg_s1 3  signed_reg_s1 1  vredand_vs_reg_s1 1  vredor_vs_reg_s1 1
        vredxor_vs_reg_s1 1  vdType_reg_s1 4  isVredmax_reg_s1 1  isVredmin_reg_s1 1
        vs12m_bits_reg_s1 256  widen_reduction_uop_reg_s1 1  alu_uop_reg_s1 1
        widen_alu_uop_reg_s1 1  vs1_zero_reg_s1 64  vs1_zero_logical_reg_s1 64
        vd_reg 128  old_vd_reg 128  signed_reg 1  vd_vsew_reg 2  ta_reg 1  vl_reg 8
        isVredmax_reg 1  isVredmin_reg 1  reg_vredand_vs 1  reg_vredor_vs 1
        reg_vredxor_vs 1  alu_uop_reg 1  widen_alu_uop_reg 1  vdType_reg 2
    }
    set ok 0
    set bad 0
    set nreg 0
    foreach {reg w} $regs {
        incr nreg
        if {$w == 1} {
            set pairs [list "r:/WORK/VIAlu/vReduAlu/${reg}_reg" "i:/WORK/VIAlu/u_core/vReduAlu/u_core/${reg}_reg"]
        } else {
            set pairs {}
            for {set b 0} {$b < $w} {incr b} {
                lappend pairs "r:/WORK/VIAlu/vReduAlu/${reg}_reg\[$b\]" "i:/WORK/VIAlu/u_core/vReduAlu/u_core/${reg}_reg\[$b\]"
            }
        }
        foreach {r i} $pairs {
            if {[set_user_match -type cell $r $i]} { incr ok } else {
                incr bad
                if {$bad <= 10} { puts "VIALU_REDU_PIN_PRE_FAIL: $r <-> $i" }
            }
        }
    }
    puts "VIALU_REDU_PIN_PRE_END $top regs=$nreg ok=$ok bad=$bad expect=817"
    if {$nreg != 33 || $bad != 0 || $ok != 817} { error "VIALU_REDU_PIN_PRE_COUNT regs=$nreg ok=$ok bad=$bad expect=817" }
}
_vialu_redu_pin_pre
