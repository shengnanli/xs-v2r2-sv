# =============================================================================
# PtwCache「匹配后」钉点：把 golden 与重写核里**同为死位**的 60 个未读寄存器位一一配对。
# 由 ut_common.mk 作为 FM_PIN_TCL 传入（首次 match 之后执行），跑在 sidecar 的 safe interp 里。
#
# 为什么必须钉（第 3 轮实测 evidence/6a102f7a5101/PtwCache/，不是推测）
# ------------------------------------------------------------------
# FM_MERGE_DUP=false 后 strict 跑成：native SUCCEEDED / passing 143717 / failing 0 /
# unverified 0 / unmatched 比较点 0(0)，卡点是 unread：matched_nc 20 对 + **unmatched unread
# ref 60 / impl 61**。unmatched unread 单开 vmucp 必然空转（加强只作用于 matched 点），
# 所以顺序是：先配对（本文件），再加强（Makefile 的 vmucp + fm_target_config/PtwCache.tcl）。
# impl 侧那多出来的 1 个（sp_hitdata_ck[prefetch]，impl 独有死位）已在 RTL 里消掉，
# 消掉之后两侧各 60，才有双射可言。
#
# 60 个点是哪些、为什么两侧都死（五族，逐位对称，无第六族、无落单；从 native_facts.json 枚举）
# ------------------------------------------------------------------
#  A. 32 个  ref  l2_<i>_prefetch_reg / l3_<i>_prefetch_reg            (i=0..15)
#            impl u_core/l2_entry_reg[<i>][prefetch] / l3_entry_reg[<i>][prefetch]
#     死因：l2/l3 表项的 prefetch 位只在 hitPre/l2Pre 这条"命中项的 pre"链上被读，而那条链
#     的终点 resp_res_l{2,3}_pre 在 golden 里无读者（io_resp_bits_prefetch 只取 sp/l0 那一路），
#     firtool 留着寄存器、消了读者；重写核照抄了表项字段集合 ⇒ 对称死位。
#  B.  4 个  ref  hitPre_r_reg / l3Pre_r_reg / hitPre_r_1_reg / l2Pre_reg
#            impl u_core/l3_pre_r_reg / l3_pre_ck_reg / l2_pre_r_reg / l2_pre_ck_reg
#     同一条链上的 delay/check 两级打拍（l3 一对、l2 一对），死因同 A。
#  C.  4 个  ref  data_resp_r_<w>_entries_prefetch_reg / l1_ramDatas_<w>_entries_prefetch_reg (w=0,1)
#            impl u_core/l1_resp_r_reg[<w>][prefetch] / l1_ramdata_reg[<w>][prefetch]
#     l1 SRAM 读出的 prefetch 位两级打拍，终点 resp_res_l1_pre 同样无读者（该点本身是 matched_nc）。
#  D.  8 个  ref  wakeup_req_delay_tag_reg[3..8] / wakeup_req_delay_way_info_reg[0] / wakeup_req_way_info_reg[0]
#            impl u_core/wk_d_tag_reg[3..8]      / wk_d_way_reg[0]                  / wk_way_reg[0]
#     golden 只读 tag[2:0]（sector 下标）与 tag[37:9]（比较高位）、way_info[3:1]（编码成 2 位）；
#     tag[8:3] 与 way_info[0] 无读出路径，重写核 bug-for-bug 照抄整条寄存器。
#  E. 12 个  ref  mbistPlL0/addrReg_reg[0..6], mbistPlL0/addrRdReg_reg[6],
#                 mbistPlL1/addrReg_reg[0..2], mbistPlL1/addrRdReg_reg[2]
#            impl u_core/u_mbist_l0/u_core/同名, u_core/u_mbist_l1/u_core/同名
#     两个 MBIST 分发级（本仓重写件 rtl/dft/MbistPipePtwL{0,1}.sv → 共享核 xs_mbist_pipe_core）里
#     地址寄存器的高位/整条：golden 的 MbistPipeline 也存了它们、下游只取部分位；两侧同构。
#     差别只在层次名（golden 扁平 mbistPlL0 vs impl u_mbist_l0/u_core）。
#
# ★_expect 是机械推导的，不是抄来的数字★（从 G1 golden 现数）：
#   A  grep -cE '^\s*reg\s+l[23]_[0-9]+_prefetch;' PtwCache.sv            -> 32
#   B  hitPre_r / hitPre_r_1 / l3Pre_r / l2Pre 各一条 reg                 ->  4
#   C  grep -cE '(data_resp_r|l1_ramDatas)_[01]_entries_prefetch;'        ->  4
#   D  wakeup_req_delay_tag[8:3] 6 + delay_way_info[0] 1 + way_info[0] 1  ->  8
#   E  实测 native_facts.json unmatched_unread_ref 里 mbistPl* 条目        -> 12
#   合计 60。
#
# ★fail-closed★（照 RenameBuffer/fm_pins.tcl 的五层判据，逐字同样的理由）：
#   1. 每条 ref 未读点必须能被五条结构规则之一解析；形状不符即 error（不盲钉）；
#   2. 由 ref 推出的 impl 路径必须确实出现在实测 impl 未读集合里（防凭空造点）；
#   3. 同一条 impl 路径不许被钉两次；
#   4. 每一次 set_user_match 都必须返回 1（它从不抛异常，catch 是空守卫）；
#   5. 钉点条数必须同时等于 impl 侧未读点数和字面整数 _expect=60。
# ★中止一律用 error，不用 exit★（safe interp 隐藏 exit）。★puts 一律 ASCII★（fm.log 非 UTF-8）。
# =============================================================================

proc ptw_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        error "PTWCACHE_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _expect 60
set _ref  [ptw_unread reference]
set _impl [ptw_unread implementation]

puts "PTWCACHE_PIN_BEGIN PtwCache expect=$_expect ref=[llength $_ref] impl=[llength $_impl]"
set _pinned 0
set _used   {}
set _nA 0 ; set _nB 0 ; set _nC 0 ; set _nD 0 ; set _nE 0
# B 族是四个固定名字的一一对应表
array set _bmap {
    hitPre_r_reg   l3_pre_r_reg
    l3Pre_r_reg    l3_pre_ck_reg
    hitPre_r_1_reg l2_pre_r_reg
    l2Pre_reg      l2_pre_ck_reg
}
array set _dmap {
    wakeup_req_delay_tag_reg      wk_d_tag_reg
    wakeup_req_delay_way_info_reg wk_d_way_reg
    wakeup_req_way_info_reg       wk_way_reg
}
array set _cmap {
    data_resp_r    l1_resp_r_reg
    l1_ramDatas    l1_ramdata_reg
}
foreach r $_ref {
    set i ""
    # A. l{2,3}_<i>_prefetch_reg
    if {[regexp {^r:(/WORK/[^/]+)/(l[23])_(\d+)_prefetch_reg$} $r -> scope lvl idx]} {
        set i "i:$scope/u_core/${lvl}_entry_reg\[$idx\]\\\[prefetch\]"
        incr _nA
    # B. hitPre_r / l3Pre_r / hitPre_r_1 / l2Pre
    } elseif {[regexp {^r:(/WORK/[^/]+)/(hitPre_r_reg|l3Pre_r_reg|hitPre_r_1_reg|l2Pre_reg)$} $r -> scope nm]} {
        set i "i:$scope/u_core/$_bmap($nm)"
        incr _nB
    # C. data_resp_r_<w>_entries_prefetch_reg / l1_ramDatas_<w>_entries_prefetch_reg
    } elseif {[regexp {^r:(/WORK/[^/]+)/(data_resp_r|l1_ramDatas)_([01])_entries_prefetch_reg$} $r -> scope nm w]} {
        set i "i:$scope/u_core/$_cmap($nm)\[$w\]\\\[prefetch\]"
        incr _nC
    # D. wakeup_req_delay_tag_reg[3..8] / wakeup_req_delay_way_info_reg[0] / wakeup_req_way_info_reg[0]
    } elseif {[regexp {^r:(/WORK/[^/]+)/(wakeup_req_delay_tag_reg|wakeup_req_delay_way_info_reg|wakeup_req_way_info_reg)\[(\d+)\]$} $r -> scope nm bit]} {
        if {$nm eq "wakeup_req_delay_tag_reg" && ($bit < 3 || $bit > 8)} {
            error "PTWCACHE_PIN_SHAPE=$r (tag bit outside 3..8)"
        }
        if {$nm ne "wakeup_req_delay_tag_reg" && $bit != 0} {
            error "PTWCACHE_PIN_SHAPE=$r (way_info bit != 0)"
        }
        set i "i:$scope/u_core/$_dmap($nm)\[$bit\]"
        incr _nD
    # E. mbistPlL{0,1}/addrReg_reg[k] / addrRdReg_reg[k]
    } elseif {[regexp {^r:(/WORK/[^/]+)/mbistPlL([01])/(addrReg_reg|addrRdReg_reg)\[(\d+)\]$} $r -> scope lv nm bit]} {
        set i "i:$scope/u_core/u_mbist_l$lv/u_core/$nm\[$bit\]"
        incr _nE
    } else {
        puts "PTWCACHE_PIN_ERROR: unexpected ref unread point $r"
        puts "  only 5 families accepted (A l2/l3 prefetch, B hitPre/l2Pre/l3Pre, C l1 prefetch, D wakeup tag/way bits, E mbist addr bits)"
        puts "  a different shape means something changed -- stop and diagnose, do NOT blind-pin"
        error "PTWCACHE_PIN_SHAPE=$r"
    }
    if {[lsearch -exact $_impl $i] < 0} {
        puts "PTWCACHE_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
        error "PTWCACHE_PIN_NOT_MEASURED=$i"
    }
    if {[lsearch -exact $_used $i] >= 0} {
        puts "PTWCACHE_PIN_ERROR: impl path pinned twice (over-pinning): $i"
        error "PTWCACHE_PIN_DUP=$i"
    }
    if {![set_user_match $r $i]} {
        puts "PTWCACHE_PIN_FAIL: set_user_match returned 0 for $r <-> $i"
        error "PTWCACHE_PIN_MISS=$r"
    }
    lappend _used $i
    incr _pinned
}
puts "PTWCACHE_PIN_END PtwCache n=$_pinned miss=0 expect=$_expect"
if {$_pinned != [llength $_impl]} {
    puts "PTWCACHE_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
    error "PTWCACHE_PIN_BIJECTION=$_pinned"
}
if {$_pinned != $_expect} {
    puts "PTWCACHE_PIN_ERROR: pinned $_pinned but expected $_expect (60 = 32 A + 4 B + 4 C + 8 D + 12 E)"
    error "PTWCACHE_PIN_COUNT=$_pinned"
}
if {$_nA != 32 || $_nB != 4 || $_nC != 4 || $_nD != 8 || $_nE != 12} {
    puts "PTWCACHE_PIN_ERROR: family counts A=$_nA B=$_nB C=$_nC D=$_nD E=$_nE differ from 32/4/4/8/12"
    error "PTWCACHE_PIN_FAMILY=$_nA/$_nB/$_nC/$_nD/$_nE"
}
puts "PTWCACHE_PINS: pinned $_pinned pairs (A l2/l3 prefetch $_nA / B pre pipeline $_nB / C l1 prefetch $_nC / D wakeup bits $_nD / E mbist addr $_nE)"
puts "PTWCACHE_PINS: ref [llength $_ref] / impl [llength $_impl] -- bijection holds, no duplicate pins"
puts "PTWCACHE_PINS: final criterion is external -- unmatched unread must reach 0 after last match; vmucp then compares 20+60 points (passing 143717 -> 143797)"
