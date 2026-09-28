# MutiLevelPrefetchFilter FM「匹配后」钉点 —— 只消一个命名鸿沟，不约束 ref、不放宽 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 对象：golden 的 1 位死寄存器 REG（= RegNext(s1_l1_valid)，只喂综合口径下已删掉的
#   l1_hash_conflict 性能计数器）。重写核照抄了它，但 golden 同时还有 REG_6..REG_37
#   （每项一份 RegNext(io.flush)），核里用数组 REG[6:37] 表达后者 —— SV 里一个作用域
#   不能既有数组 REG 又有标量 REG，于是标量只能叫 REG_0。
#   FM 按名字配不上（REG_reg vs REG_0_reg），两侧又都没有读者（unread），签名分析也不管它：
#   2026-09-28 lane 内诊断跑实测 "1(1) Unmatched reference(implementation) unread points"，
#   即 ref REG_reg / impl u_core/REG_0_reg 各剩一个。
# 规则：ref r:/WORK/MutiLevelPrefetchFilter/REG_reg <-> impl i:/WORK/MutiLevelPrefetchFilter/u_core/REG_0_reg
#   两者 D 端同为 s1_l1_valid、都不复位 —— 同源同构。
# fail-closed：set_user_match 返回值必须为 1（它从不抛异常，0 = 没配上），总数字面 1。
# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。
# ---------------------------------------------------------------------------
proc _mlpf_pin_perf_valid { } {
    set _expect 1
    puts "MLPF_PIN_BEGIN MutiLevelPrefetchFilter expect=$_expect"
    set n 0
    set rpath "r:/WORK/MutiLevelPrefetchFilter/REG_reg"
    set ipath "i:/WORK/MutiLevelPrefetchFilter/u_core/REG_0_reg"
    if {![set_user_match $rpath $ipath]} {
        puts "MLPF_PIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"
        error "MLPF_PIN_MISS=$rpath"
    }
    incr n
    puts "MLPF_PIN_END MutiLevelPrefetchFilter n=$n expect=$_expect"
    if {$n != $_expect} {
        puts "MLPF_PIN_ERROR: pinned $n but expected $_expect"
        error "MLPF_PIN_COUNT=$n"
    }
}
_mlpf_pin_perf_valid
