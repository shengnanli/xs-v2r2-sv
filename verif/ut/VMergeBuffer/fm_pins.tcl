# VMergeBuffer FM 钉点（VLMergeBufferImp / VSMergeBufferImp）—— **只消命名鸿沟**：
# 不约束 ref、不放宽任何 appvar、不扩黑盒、不 dont_verify。
# ---------------------------------------------------------------------------
# 为什么需要（2026-09-28 实测，VSMergeBufferImp 首次试跑，没有本文件）：
#   golden 把 Reg(Vec(16, MBufferBundle)) 展平成 `entries_<i>_<字段>_reg[<b>]`，
#   重写核按 SoA 存成每字段一个数组 `u_core/entries_<字段>_reg[<i>][<b>]`。
#   条目下标在 golden 名字的中间、在核名字的末尾，FM 的按名匹配与
#   scripts/fm_eq.tcl 的 auto_match_flattened_arrays（只认"下标在末尾"）都配不上；
#   签名分析一个也没配上（16 个条目逐位对称）：
#     2352 matched by name / 0 by signature / 17680(17680) unmatched compare points。
# 所以按下表的**机械规则**把两侧未匹配点逐一 set_user_match（ref 叶名 -> impl 叶名）：
#   entries_<i>_exceptionVec_<n>_reg     -> entries_exceptionVec_reg[i][k]   k = n 在本单元 exceptionOut 里的序号
#   entries_<i>_<f>_reg[b]               -> entries_<f>_reg[i][b]
#   io_feedback_<d>_valid_REG_reg        -> fb_valid_REG_reg[d]
#   io_feedback_<d>_bits_r_<f>_reg[b]    -> fb_r_<f>_reg[d][b]
#   （仅 load 版：流水结果打一拍的各份寄存器）
#   pipeValidReg_<i>_reg                 -> wbv_valid_reg[i]
#   pipeBitsReg_<i>_exceptionVec_<n>_reg -> wbv_exceptionVec_reg[i][k]
#   pipeBitsReg_<i>_<f>_reg[b]           -> wbv_<f>_reg[i][b]
#   mergePortMatrixHasExcpWrap_<i>_<j>_reg -> wbv_hasExcp_reg[i][j]
#   mergedByPrevPortVecWrap_<i>_reg      -> wbv_mergedByPrev_reg[i]
#   latchWbValid[_<i>] / latchWbIndex / latchFlowNum / latchMergeByPre
#                                        -> cnt_valid / cnt_idx / cnt_flowNum / cnt_mergedByPrev _reg[i]
#   pipewbValidReg_<i>_REG / wbIndexReg_<i>_r / mergeDataReg_<i>_r
#                                        -> pipewbValidReg / wbIndexReg / mergeDataReg _reg[i]
#   brodenMergeDataReg[_<i>] / brodenMergeMaskReg / mergedByPrevPortReg / regOffsetReg / isusMerge
#                                        -> 同名 _reg[i]（无后缀 = 口 0）
# 只管本层寄存器（ref 顶层直属 / impl u_core 直属）；impl 叶名去掉 generate 块前缀。
#
# 四道 fail-closed：
#   (1) 每个 ref 未匹配点都必须能按上表算出 impl 叶名（算不出 = 表不全，error）；
#   (2) 算出的叶名必须在 impl 未匹配点里且未被用过（双射，error）；
#   (3) set_user_match 必须返回 1（它从不抛异常，返回 0 = 没配上，error）；
#   (4) 配完 impl 侧必须一个不剩（error）。
# 跑在 sidecar 的 safe child interp 里：只用 report_unmatched_points -list / set_user_match /
# match / puts / error（safe interp 没有 exit、file、redirect）。
# ---------------------------------------------------------------------------

proc _mb_leaf {p} {
    set i [string last "/" $p]
    if {$i >= 0} { set p [string range $p [expr {$i + 1}] end] }
    set j [string last "." $p]
    if {$j >= 0} { set p [string range $p [expr {$j + 1}] end] }
    return $p
}

# 异常号 -> 压缩序号（与核的 EXC_SEL 同序：从低到高）
proc _mb_exc_k {top n} {
    if {$top eq "VLMergeBufferImp"} { set lst {3 4 5 13 19 21} } else { set lst {3 6 7 15 19 23} }
    set k [lsearch -exact $lst $n]
    if {$k < 0} { error "MB_PIN_BAD_EXC $top exceptionVec_$n" }
    return $k
}

# ref 叶名 -> impl 叶名；配不上返回空串
proc _mb_partner {top leaf} {
    # 位下标尾巴
    set bit ""
    if {[regexp {^(.*_reg)(\[\d+\])$} $leaf -> base b]} { set leaf $base; set bit $b }
    if {[regexp {^entries_(\d+)_exceptionVec_(\d+)_reg$} $leaf -> i n]} {
        return "entries_exceptionVec_reg\[$i\]\[[_mb_exc_k $top $n]\]$bit"
    }
    if {[regexp {^entries_(\d+)_(\w+)_reg$} $leaf -> i f]} {
        return "entries_${f}_reg\[$i\]$bit"
    }
    if {[regexp {^io_feedback_(\d+)_valid_REG_reg$} $leaf -> d]} {
        return "fb_valid_REG_reg\[$d\]$bit"
    }
    if {[regexp {^io_feedback_(\d+)_bits_r_(\w+)_reg$} $leaf -> d f]} {
        return "fb_r_${f}_reg\[$d\]$bit"
    }
    if {[regexp {^pipeValidReg_(\d+)_reg$} $leaf -> i]} {
        return "wbv_valid_reg\[$i\]$bit"
    }
    if {[regexp {^pipeBitsReg_(\d+)_exceptionVec_(\d+)_reg$} $leaf -> i n]} {
        return "wbv_exceptionVec_reg\[$i\]\[[_mb_exc_k $top $n]\]$bit"
    }
    if {[regexp {^pipeBitsReg_(\d+)_(\w+)_reg$} $leaf -> i f]} {
        return "wbv_${f}_reg\[$i\]$bit"
    }
    if {[regexp {^mergePortMatrixHasExcpWrap_(\d+)_(\d+)_reg$} $leaf -> i j]} {
        return "wbv_hasExcp_reg\[$i\]\[$j\]$bit"
    }
    if {[regexp {^mergedByPrevPortVecWrap_(\d+)_reg$} $leaf -> i]} {
        return "wbv_mergedByPrev_reg\[$i\]$bit"
    }
    foreach {g im} {latchWbValid cnt_valid latchWbIndex cnt_idx latchFlowNum cnt_flowNum
                    latchMergeByPre cnt_mergedByPrev
                    brodenMergeDataReg brodenMergeDataReg brodenMergeMaskReg brodenMergeMaskReg
                    mergedByPrevPortReg mergedByPrevPortReg regOffsetReg regOffsetReg
                    isusMerge isusMerge} {
        if {[regexp "^${g}(?:_(\\d+))?_reg\$" $leaf -> i]} {
            if {$i eq ""} { set i 0 }
            return "${im}_reg\[$i\]$bit"
        }
    }
    foreach {g sfx} {pipewbValidReg REG wbIndexReg r mergeDataReg r} {
        if {[regexp "^${g}_(\\d+)_${sfx}_reg\$" $leaf -> i]} {
            return "${g}_reg\[$i\]$bit"
        }
    }
    return ""
}

proc _mb_pin {} {
    set top $::top
    # 期望配对数（字面声明，test_fm_pins_wellformed P3）：实测值，evidence/0282c93b52b4
    # （VL: MB_PIN_END n=18807 impl_left=0；VS: n=17584 impl_left=0）。规则表是按叶名双射的，
    # 数量只会因 RTL/golden 的寄存器集合变化而变 —— 那正是要停下来重看的时候。
    switch -exact -- $top {
        VLMergeBufferImp { set expect 18807 }
        VSMergeBufferImp { set expect 17584 }
        default { error "MB_PIN_BAD_TOP=$top" }
    }
    set refs  [concat [report_unmatched_points -reference -list] \
                      [report_unmatched_points -reference -status unread -list]]
    set impls [concat [report_unmatched_points -implementation -list] \
                      [report_unmatched_points -implementation -status unread -list]]
    # 只处理本层（核自己）的寄存器：ref 顶层直属、impl u_core 直属（generate 块用 "." 连接，
    # 不算下一层）。子模块 FreeList(_1) 的寄存器不在本表管辖，留给第二次 match 的签名分析
    # （与它单独签核时一样）；流水缓冲的 payload 已由 fm_pins_pre.tcl 在匹配前钉好。
    set refs  [lsearch -all -inline -regexp $refs  "^r:/WORK/$top/\[^/\]+\$"]
    set impls [lsearch -all -inline -regexp $impls "^i:/WORK/$top/u_core/\[^/\]+\$"]
    array set impl_lut {}
    foreach ip [lsort -unique $impls] {
        set lf [_mb_leaf $ip]
        if {[info exists impl_lut($lf)]} { error "MB_PIN_DUP_IMPL_LEAF $lf" }
        set impl_lut($lf) $ip
    }
    set refs [lsort -unique $refs]
    puts "MB_PIN_BEGIN top=$top ref_unmatched=[llength $refs] impl_unmatched=[array size impl_lut]"
    set n 0
    foreach rpath $refs {
        set want [_mb_partner $top [_mb_leaf $rpath]]
        if {$want eq ""} {
            puts "MB_PIN_NO_RULE: $rpath"
            error "MB_PIN_NO_RULE=$rpath"
        }
        if {![info exists impl_lut($want)]} {
            puts "MB_PIN_NO_PARTNER: $rpath -> $want"
            error "MB_PIN_NO_PARTNER=$rpath"
        }
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "MB_PIN_FAIL: set_user_match returned 0 for $rpath <-> $impl_lut($want)"
            error "MB_PIN_FAIL=$rpath"
        }
        unset impl_lut($want)
        incr n
    }
    puts "MB_PIN_END top=$top n=$n impl_left=[array size impl_lut] expect=$expect"
    if {$n != $expect} { error "MB_PIN_COUNT=$n expect=$expect" }
    if {[array size impl_lut] != 0} {
        foreach k [lsort [array names impl_lut]] { puts "MB_PIN_IMPL_LEFT: $impl_lut($k)" }
        error "MB_PIN_IMPL_LEFT=[array size impl_lut]"
    }
}

_mb_pin
