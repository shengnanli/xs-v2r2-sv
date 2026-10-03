# BankedDataArray FM「匹配前」钉点 —— 由 scripts/gen_bankeddataarray.py 生成，勿手改。
# 只消命名鸿沟（golden 平铺 _k 后缀 vs 重写 [b][w] 二维数组）：不约束 ref、不放宽 appvar、
# 不扩黑盒、不 dont_verify。依据见生成器文件头。
if {$top ne "BankedDataArray"} { error "BDA_PREPIN_WRONG_TOP=$top" }
set _bda_n 0
for {set _b 0} {$_b < 8} {incr _b} {
    for {set _w 0} {$_w < 4} {incr _w} {
        set _k [expr {$_b * 4 + $_w}]
        if {$_k == 0} { set _sfx "" } else { set _sfx "_$_k" }
        set _r "r:/WORK/BankedDataArray/ecc_data_delayed_REG${_sfx}_reg"
        set _i "i:/WORK/BankedDataArray/ecc_data_delayed_REG_reg\[$_b\]\[$_w\]"
        if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }
        incr _bda_n
        for {set _bit 0} {$_bit < 72} {incr _bit} {
            set _r "r:/WORK/BankedDataArray/ecc_data_delayed${_sfx}_reg\[$_bit\]"
            set _i "i:/WORK/BankedDataArray/ecc_data_delayed_reg\[$_b\]\[$_w\]\[$_bit\]"
            if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }
            incr _bda_n
        }
    }
}
for {set _b 0} {$_b < 8} {incr _b} {
    for {set _w 0} {$_w < 4} {incr _w} {
        set _p "data_banks_0_$_b/data_bank_$_w"
        set _r "r:/WORK/BankedDataArray/$_p/respReg_reg"
        set _i "i:/WORK/BankedDataArray/$_p/u_core/g_nomcp.respReg_reg"
        if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }
        incr _bda_n
        for {set _bit 0} {$_bit < 72} {incr _bit} {
            set _r "r:/WORK/BankedDataArray/$_p/rdataReg_reg\[$_bit\]"
            set _i "i:/WORK/BankedDataArray/$_p/u_core/rdataReg_reg\[$_bit\]"
            if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }
            incr _bda_n
        }
    }
}
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[0\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[0\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[0\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[1\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[1\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[1\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[2\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[2\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[2\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[3\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[3\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[3\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[4\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[4\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[4\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[5\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[5\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[5\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[6\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[6\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[6\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[7\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[7\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[7\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrReg_reg\[8\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrReg_reg\[8\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrReg_reg\[8\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/addrRdReg_reg\[8\]" "i:/WORK/BankedDataArray/mbistPl/u_core/addrRdReg_reg\[8\]"]} { error "BDA_PREPIN_MISS=mbistPl/addrRdReg_reg\[8\]" } ; incr _bda_n
if {![set_user_match "r:/WORK/BankedDataArray/mbistPl/beReg_reg" "i:/WORK/BankedDataArray/mbistPl/u_core/beReg_reg\[0\]"]} { error "BDA_PREPIN_MISS=mbistPl/beReg_reg" } ; incr _bda_n
puts "BDA_PREPIN_END n=$_bda_n expect=4683"
if {$_bda_n != 4683} { error "BDA_PREPIN_COUNT=$_bda_n" }
