# =============================================================================
# fm_pins_pre.tcl —— Reduction「匹配前」钉点（只 set_user_match，不约束 ref）
#
# 要消的名差：重写件的全部寄存器都在 u_core 里、且与 golden 同名（Scala 名），
#   golden 在顶层：r:/WORK/Reduction/<reg>_reg[b] <-> i:/WORK/Reduction/u_core/<reg>_reg[b]。
# 为什么全钉而不只钉死位：vdType_reg_s1[3:2] 两侧同为无读者死位（只用 [1:0]），签名匹配配不上；
#   其余寄存器一并钉，让 33 个寄存器在同一条规则下配对，配对不依赖签名分析。
# 用 -type cell：钉的是 DFF 单元（HPerfMonitor_3 的教训：不带类型可能绑到同名线）。
# 期望数（字面）：golden 顶层 33 个寄存器共 817 位（逐个见下表，与 golden reg 声明一一对应）。
# fail-closed：set_user_match 不抛异常，逐条数返回值；拒一条或总数 != 817 就 error。进 fm.log 的输出全 ASCII。
# =============================================================================
proc _reduction_pin_pre { } {
    set top $::top
    if {$top ne "Reduction"} { error "REDUCTION_PIN_UNKNOWN_TOP=$top" }
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
            set pairs [list "r:/WORK/Reduction/${reg}_reg" "i:/WORK/Reduction/u_core/${reg}_reg"]
        } else {
            set pairs {}
            for {set b 0} {$b < $w} {incr b} {
                lappend pairs "r:/WORK/Reduction/${reg}_reg\[$b\]" "i:/WORK/Reduction/u_core/${reg}_reg\[$b\]"
            }
        }
        foreach {r i} $pairs {
            if {[set_user_match -type cell $r $i]} { incr ok } else {
                incr bad
                if {$bad <= 10} { puts "REDUCTION_PIN_PRE_FAIL: $r <-> $i" }
            }
        }
    }
    puts "REDUCTION_PIN_PRE_END $top regs=$nreg ok=$ok bad=$bad expect=817"
    if {$nreg != 33 || $bad != 0 || $ok != 817} { error "REDUCTION_PIN_PRE_COUNT regs=$nreg ok=$ok bad=$bad expect=817" }
}
_reduction_pin_pre
