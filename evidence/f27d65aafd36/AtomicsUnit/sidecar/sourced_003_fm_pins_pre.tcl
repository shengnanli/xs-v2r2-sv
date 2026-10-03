# =============================================================================
# fm_pins_pre.tcl —— AtomicsUnit「匹配前」钉点（只 set_user_match -type cell，不约束 ref）
#
# 要消的名差：golden 把 4 个触发器槽的 tdata2 平铺成 tdata_<j>_tdata2（DFF 单元 tdata_<j>_tdata2_reg[b]），
#   可读核存成数组 tdata_tdata2[j]（单元 u_core/tdata_tdata2_reg[j][b]）。
# 为什么要钉：首跑（evidence/5a3282d30ab1/AtomicsUnit，vmucp 关）里 [49:0] 已被签名匹配配上，
#   但 [63:50] 两侧同为无读者死位（TriggerCmp 只比低 50 位），签名匹配配不上，成了 56 ↔ 56 未配 unread。
#   这里把 4 槽 × 64 位全部按同一条规则钉上（不只钉死位），让整个寄存器在一条规则下配对。
# -type cell：钉 DFF 单元本身，避免与同名线二义（HPerfMonitor_3 实测踩过）。
# 期望数机械推导：4 × 64 = 256。fail-closed：逐条数返回值，拒一条或总数不等就 error。输出全 ASCII。
# =============================================================================
proc _atom_pin_pre { } {
    if {$::top ne "AtomicsUnit"} { error "ATOM_PIN_UNKNOWN_TOP=$::top" }
    set ok 0
    set bad 0
    for {set j 0} {$j < 4} {incr j} {
        for {set b 0} {$b < 64} {incr b} {
            set r "r:/WORK/AtomicsUnit/tdata_${j}_tdata2_reg\[$b\]"
            set i "i:/WORK/AtomicsUnit/u_core/tdata_tdata2_reg\[$j\]\[$b\]"
            if {[set_user_match -type cell $r $i]} { incr ok } else {
                incr bad
                if {$bad <= 10} { puts "ATOM_PIN_FAIL: $r <-> $i" }
            }
        }
    }
    puts "ATOM_PIN_END ok=$ok bad=$bad expect=256"
    if {$bad != 0 || $ok != 256} { error "ATOM_PIN_COUNT ok=$ok bad=$bad expect=256" }
}
_atom_pin_pre
