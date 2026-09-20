# VARIANTS: TLBFA TLBFA_1 TLBFA_2 TLBFA_3
# ---------------------------------------------------------------------------
# TLBFA 家族钉点文件的**夹具**：给 scripts/pin_call_equiv.py 用，不参与任何 FM 跑。
#
# 为什么需要它：本钉点文件是"动态"的 —— 它现场调 report_unmatched_points 把两侧
# 未匹配的未读点读回来再按结构配对。所以它发出的 set_user_match 调用序列是
# **那个查询输出的函数**。要判"改动是不是守卫专属"，必须先把那个输入固定住。
#
# 点名结构照钉点文件自己声明的规则造；数量是机械推导的（与钉点文件里的 _expect 同源）：
#   每端口 11 个死位（golden reqVpn 是 reg [37:0]，全部读出切片最高只到 bit26
#   -> bit37..27 无读者），端口数 = golden 里 `reg [37:0] reqVpn[_N];` 的条数：
#     TLBFA 3 / TLBFA_1 4 / TLBFA_2 2 / TLBFA_3 2
# ★夹具算错了不会掩盖什么★：钉点文件自己的期望值守卫会当场抛，闸就红。
# ---------------------------------------------------------------------------
proc _fx_ports {} {
    global top
    switch -exact -- $top {
        TLBFA   { return 3 }
        TLBFA_1 { return 4 }
        TLBFA_2 { return 2 }
        TLBFA_3 { return 2 }
    }
    error "TLBFA fixture: unknown variant $top"
}
proc report_unmatched_points {args} {
    global top
    set ports [_fx_ports]
    set ref {} ; set impl {}
    for {set p 0} {$p < $ports} {incr p} {
        set sfx [expr {$p == 0 ? "" : "_$p"}]
        for {set b 27} {$b <= 37} {incr b} {
            lappend ref  "r:/WORK/$top/reqVpn${sfx}_reg\[$b\]"
            lappend impl "i:/WORK/$top/u_core/g_port\[$p\].req_vpn_q_reg\[$b\]"
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
