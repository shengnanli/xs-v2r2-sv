# Rename FM「匹配前」钉点 —— 只消 perf 高位寄存器的命名鸿沟，不约束 ref、不放宽 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：Rename 的 20 路 FreeList perf 事件寄存器(io_perf_10..29_value 两级各 6 位)。
# golden 与重写核结构逐位相同：REG <= FreeList 的 6 位输出({5'h0, 事件位})，REG_1 <= REG，
# 输出 = REG_1。所以两侧 [5:1] 都是"D 端恒 0、不复位"的寄存器 —— FM 把它们判成
# "assumed-to-toggle 初值的常量寄存器"并折叠掉。
# ★实测的坑(2026-09-27 首次整证)★：折叠是**逐侧独立**做的，两侧折掉的不是同一批：
#   ref 折了 io_perf_10..19_value_REG[5:1] + 全部 REG_1[5:1]，impl 折了 perfFl_REG[10..19][5:1]
#   (= io_perf_20..29) + 全部 REG_1[5:1]，于是两边各剩 50 个"配不上"的常量点
#   (50(50) Unmatched compare points，两侧分别是 io_perf_20..29_value_REG_reg[5:1] 与
#   perfFl_REG_reg[0..9][5:1])，native 照样 SUCCEEDED 但 strict 判 PARTIAL(unmatched!=0)。
# 修法：在第一次 match **之前**按机械规则把这 200 个位逐一 set_user_match：
#   ref  io_perf_<n>_value_REG_reg[<b>]    <-> impl u_core/perfFl_REG_reg[<n-10>][<b>]
#   ref  io_perf_<n>_value_REG_1_reg[<b>]  <-> impl u_core/perfFl_REG_1_reg[<n-10>][<b>]
#   n ∈ 10..29，b ∈ 1..5(bit0 是活位，FM 自己按签名配得上，不钉)。
# 配好的对子随后被 FM 一起折叠或一起比较，不再各折各的。
# 名字不带层次前缀之外的猜测：ref 顶层 /WORK/Rename/，impl 核层 /WORK/Rename/u_core/。
# fail-closed：每一次 set_user_match 都必须返回 1(它从不抛异常，返回 0 = 没配上)，
# 配对数必须等于字面整数 200 = 20 路 × 2 级 × 5 位。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。
# ---------------------------------------------------------------------------
proc _rn_pre_pin_perf_hi { } {
    set _expect 200
    puts "RN_PREPIN_BEGIN Rename expect=$_expect"
    set n 0
    for {set p 10} {$p < 30} {incr p} {
        set k [expr {$p - 10}]
        for {set b 1} {$b <= 5} {incr b} {
            foreach {rsuf isuf} {REG REG REG_1 REG_1} {
                set rpath "r:/WORK/Rename/io_perf_${p}_value_${rsuf}_reg\[$b\]"
                set ipath "i:/WORK/Rename/u_core/perfFl_${isuf}_reg\[$k\]\[$b\]"
                if {![set_user_match $rpath $ipath]} {
                    puts "RN_PREPIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"
                    error "RN_PREPIN_MISS=$rpath"
                }
                incr n
            }
        }
    }
    puts "RN_PREPIN_END Rename n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "RN_PREPIN_ERROR: pinned $n but expected $_expect"
        error "RN_PREPIN_COUNT=$n"
    }
}
_rn_pre_pin_perf_hi
