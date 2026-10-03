# VARIANTS: PtwCache
# ---------------------------------------------------------------------------
# PtwCache 钉点文件的**夹具**（scripts/pin_call_equiv.py 用，不参与 FM 跑）。
# 见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
#
# 按 fm_pins.tcl 头部自己声明的五族结构造出两侧未读点名（60 / 60），
# 每族的规模机械推导自 G1 golden PtwCache.sv 的寄存器声明：
#   A 32 点  reg l2_<i>_prefetch; / reg l3_<i>_prefetch;          i=0..15
#   B  4 点  reg hitPre_r; l3Pre_r; hitPre_r_1; l2Pre;              (golden L4726/4750/4809/4834)
#   C  4 点  reg data_resp_r_<w>_entries_prefetch; l1_ramDatas_<w>_entries_prefetch;  w=0,1
#   D  8 点  reg [37:0] wakeup_req_delay_tag 的 [8:3]；reg [3:0] wakeup_req_delay_way_info /
#            wakeup_req_way_info 的 [0]
#   E 12 点  mbistPlL0 addrReg[6:0] + addrRdReg[6]；mbistPlL1 addrReg[2:0] + addrRdReg[2]
# impl 侧点名按 fm_pins.tcl 的推导规则给出（u_core/ 下的重写核寄存器名）。
# 列表顺序无关：钉点文件先 lsort -unique 再遍历。
#
# 已与真实运行逐调用核对：evidence/22184c5297e2/PtwCache/fm.log（receipt
# passing 143797）里钉点段的 60 次 set_user_match，与本夹具下桩跑出的 60 次逐字节一致。
# ---------------------------------------------------------------------------
proc report_unmatched_points {args} {
    global top
    set R "r:/WORK/$top"
    set I "i:/WORK/$top/u_core"
    set ref {} ; set impl {}
    # A
    foreach lvl {l2 l3} {
        for {set i 0} {$i < 16} {incr i} {
            lappend ref  "$R/${lvl}_${i}_prefetch_reg"
            lappend impl "$I/${lvl}_entry_reg\[$i\]\\\[prefetch\]"
        }
    }
    # B
    foreach {r i} {hitPre_r_reg l3_pre_r_reg  l3Pre_r_reg l3_pre_ck_reg
                   hitPre_r_1_reg l2_pre_r_reg  l2Pre_reg l2_pre_ck_reg} {
        lappend ref  "$R/$r"
        lappend impl "$I/$i"
    }
    # C
    foreach w {0 1} {
        lappend ref  "$R/data_resp_r_${w}_entries_prefetch_reg"
        lappend impl "$I/l1_resp_r_reg\[$w\]\\\[prefetch\]"
        lappend ref  "$R/l1_ramDatas_${w}_entries_prefetch_reg"
        lappend impl "$I/l1_ramdata_reg\[$w\]\\\[prefetch\]"
    }
    # D
    for {set b 3} {$b <= 8} {incr b} {
        lappend ref  "$R/wakeup_req_delay_tag_reg\[$b\]"
        lappend impl "$I/wk_d_tag_reg\[$b\]"
    }
    lappend ref  "$R/wakeup_req_delay_way_info_reg\[0\]"
    lappend impl "$I/wk_d_way_reg\[0\]"
    lappend ref  "$R/wakeup_req_way_info_reg\[0\]"
    lappend impl "$I/wk_way_reg\[0\]"
    # E
    foreach {lv hi} {0 6 1 2} {
        for {set b 0} {$b <= $hi} {incr b} {
            lappend ref  "$R/mbistPlL$lv/addrReg_reg\[$b\]"
            lappend impl "$I/u_mbist_l$lv/u_core/addrReg_reg\[$b\]"
        }
        lappend ref  "$R/mbistPlL$lv/addrRdReg_reg\[$hi\]"
        lappend impl "$I/u_mbist_l$lv/u_core/addrRdReg_reg\[$hi\]"
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
