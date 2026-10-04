# RecentRequestTable(_1) FM「匹配后」钉点 —— 只消一个命名鸿沟，不约束 ref、不放宽 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：Scala `assert(!RegNext(io.w.fire && io.r.req.fire))` 产生的 1 位寄存器 —— golden 展平名 REG，
#   重写核取语义名 rw_same_cycle_q（rtl/uncore/RecentRequestTable.sv 文件头已说明）。
#   它唯一的读者是 `ifndef SYNTHESIS 断言，FM 两侧 -define SYNTHESIS ⇒ 两侧都零扇出（unread），
#   签名分析不管零扇出点，名字又不同 ⇒ lane 内诊断跑实测两侧各剩 1 个 unmatched unread。
# 规则：r:/WORK/<top>/REG_reg <-> i:/WORK/<top>/u_core/rw_same_cycle_q_reg（两个变体同一条）。
#   两者 D 端同为 w.ready & w.valid & r.req.valid、都不复位 —— 同源同构；配上后由 vmucp 真比较
#   （verif/fm_target_config/RecentRequestTable*.tcl）。
# fail-closed：set_user_match 返回值必须为 1（它从不抛异常，0 = 没配上），总数字面 1。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。$top = 当前 FM_TOP。
# ---------------------------------------------------------------------------
proc _rrt_pin_assert_reg { t } {
    set _expect 1
    puts "RRT_PIN_BEGIN $t expect=$_expect"
    set n 0
    set rpath "r:/WORK/$t/REG_reg"
    set ipath "i:/WORK/$t/u_core/rw_same_cycle_q_reg"
    if {![set_user_match $rpath $ipath]} {
        puts "RRT_PIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"
        error "RRT_PIN_MISS=$rpath"
    }
    incr n
    puts "RRT_PIN_END $t n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "RRT_PIN_ERROR: pinned $n but expected $_expect"
        error "RRT_PIN_COUNT=$n"
    }
}
if {$top eq "RecentRequestTable" || $top eq "RecentRequestTable_1"} {
    _rrt_pin_assert_reg $top
} else {
    error "RRT_PIN_UNKNOWN_TOP=$top"
}
