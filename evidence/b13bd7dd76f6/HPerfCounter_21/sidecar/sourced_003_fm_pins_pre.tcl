# =============================================================================
# fm_pins_pre.tcl —— HPerfMonitor_3「匹配前」钉点（只 set_user_match，不约束 ref）
#
# 要消的名差：golden 把 8 个计数器平铺成实例 perfEvents_hpc / perfEvents_hpc_<N>，
#   重写件是 u_core/g_cnt[<N>].perfEvents_hpc/u_core（叶名已与 golden 同名，只差路径）。
# 要钉的对象：每个计数器的四个 5 位算子寄存器 event_op_0 / event_op_1 / event_op_2 / event_op_2_reg
#   全部 5 位。其中 [4:3] 是两侧对称的 cone-dead 位（combine 只看 op[2:0]），没有读者，签名匹配
#   配不上它们；[2:0] 一起钉，让整个寄存器在同一条规则下配对。
# 为什么改成「匹配前」：上一版（fm_pins.tcl，匹配后钉 64 个死位）实测 event_op_2[4:3] 在二次 match
#   后仍是 unread/unmatched，导致下游 event_op_2_reg[4:3] 失配 16 点（evidence/5a3282d30ab1/HPerfMonitor_3，
#   FAILED failing=16）。★根因是名字二义★：golden 有一个 reg 就叫 event_op_2_reg（第二级），它的 DFF 实例叫
#   event_op_2_reg_reg；而第一级 reg event_op_2 的 DFF 实例也叫 event_op_2_reg —— 于是 "event_op_2_reg[3]" 既是
#   第一级 DFF 的单元名、又是第二级寄存器 Q 端的线名，不带类型的 set_user_match 绑到了线上（"matched by user"
#   只有 120/160，差的 40 正是 8 × event_op_2_reg 的 5 位）。修法：set_user_match -type cell，钉的就是 DFF 单元。
# 期望数机械推导：8 计数器 × 4 寄存器 × 5 位 = 160；HPerfCounter_21 单跑时为 0（同名直接配上）。
# fail-closed：set_user_match 不抛异常，逐条数返回值；拒一条或总数不等就 error。进 fm.log 的输出全 ASCII。
# =============================================================================
proc _hperf_pin_pre { } {
    set top $::top
    if {$top eq "HPerfCounter_21"} {
        puts "HPERF_PIN_PRE $top expect=0 (same names, nothing to pin)"
        return
    }
    if {$top ne "HPerfMonitor_3"} { error "HPERF_PIN_UNKNOWN_TOP=$top" }
    set ok 0
    set bad 0
    for {set c 0} {$c < 8} {incr c} {
        set rinst [expr {$c == 0 ? "perfEvents_hpc" : "perfEvents_hpc_$c"}]
        foreach reg {event_op_0_reg event_op_1_reg event_op_2_reg event_op_2_reg_reg} {
            for {set b 0} {$b < 5} {incr b} {
                set r "r:/WORK/HPerfMonitor_3/$rinst/$reg\[$b\]"
                set i "i:/WORK/HPerfMonitor_3/u_core/g_cnt\[$c\].perfEvents_hpc/u_core/$reg\[$b\]"
                if {[set_user_match -type cell $r $i]} { incr ok } else {
                    incr bad
                    puts "HPERF_PIN_PRE_FAIL: $r <-> $i"
                }
            }
        }
    }
    puts "HPERF_PIN_PRE_END $top ok=$ok bad=$bad expect=160"
    if {$bad != 0 || $ok != 160} { error "HPERF_PIN_PRE_COUNT ok=$ok bad=$bad expect=160" }
}
_hperf_pin_pre
