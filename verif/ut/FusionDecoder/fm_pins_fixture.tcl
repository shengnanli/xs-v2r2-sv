# VARIANTS: FusionDecoder
# ---------------------------------------------------------------------------
# FusionDecoder 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 10 个点 = 两族 × 5（golden 5 个融合槽的 perf 打拍寄存器，两侧都无读者）：
#   lastFire_reg / lastFire_<k>_reg  <-> u_core/lastFire_reg[<k>]          k=0..4
#   REG_reg      / REG_<k>_reg       <-> u_core/fireDelayed_perf_reg[<k>]  k=0..4
#   （k=0 时 golden 名不带下标 —— firtool 的命名习惯，钉点文件两条 elseif 各管一半）
# 钉点文件**不**对 ref 列表排序，调用序列跟着 FM 的返回顺序走；真实 FM 返回的是
# 按名字 ASCII 序（REG_1_reg..REG_4_reg, REG_reg, lastFire_1_reg..），本夹具用 lsort 复现。
# 首跑实测 ref_unread=10 / impl_unread=10，两侧列表里没有别的点。
# 逐条核过真实 fm.log：evidence/{5bf9d7f2e62d,41fb20c06e47}/FusionDecoder/fm.log 两轮的
# 10 条 "Set a match" 回显与桩序列逐字节相同。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set ref {} ; set impl {}
    for {set k 0} {$k < 5} {incr k} {
        set s [expr {$k == 0 ? "" : "_$k"}]
        lappend ref  "r:/WORK/$top/lastFire${s}_reg"
        lappend impl "i:/WORK/$top/u_core/lastFire_reg\[$k\]"
        lappend ref  "r:/WORK/$top/REG${s}_reg"
        lappend impl "i:/WORK/$top/u_core/fireDelayed_perf_reg\[$k\]"
    }
    if {[lindex $args 0] eq "-reference"} { return [lsort $ref] }
    return [lsort $impl]
}
