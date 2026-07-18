# CtrlBlock FM 钉点(FM 审计 2026-07)
# golden(firtool 展平字段名) ↔ 手写核(struct/unpacked-array 寄存器)自动配对失败的
# 1-1 对应,按命名规则从 report_unmatched_points 现场推导后 set_user_match。
# 规则表(ref 相对路径 → impl u_core 下规范键):
#   enqRob_req_<k>_bits_r_<field>_reg[b]                      -> enqRobBits_reg[k][<field>][b]
#   delayedNotFlushedWriteBack_delayed_bits_r_<k>_exceptionVec_<j>_reg
#                                                             -> wbDelayedBits_reg[k][exceptionVec][j]
#   delayedNotFlushedWriteBack_delayed_bits_r_<k>_debug_*_reg -> wbDelayedBits_reg[k][debug_*]
#   delayedNotFlushedWriteBackNums_delayed_bits_r_<k>_reg[b]  -> wbNumsBits_reg[k][b] (k 缺省=0)
#   redirectGen_io_oldestExuRedirect_bits_r_<f>_reg[b]        -> oldestExuRedirectBits_reg[<f>][b]
#   s3_s5_redirect_next_bits_r_level/robIdx_flag/robIdx_value -> s3_s5_redirect_{level,robFlag,robValue}_reg
#   s3_s5_redirect_next_valid_last_REG_reg                    -> s3_s5_redirect_valid_reg
#   s2_s4_redirect_next_valid_last_REG_reg                    -> s2_s4_redirect_valid_reg
#   decodeBufBits_<k>_foldpc_reg[b]                           -> decodeBufBits_reg[k][foldpc][b]
#   io_perf_<n>_value_REG_reg[b] / REG_1_reg[b]               -> perfStage0/1_reg[n][b]
proc ctrlblock_pin_unmatched { top } {
    redirect -variable um_txt {report_unmatched_points}
    # impl 未匹配 DFF: 规范键(去 u_core/ 前缀与转义反斜杠) -> 实际路径
    array set ilut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rp]} { lappend refs $rp }
        if {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ip]} {
            set key $ip
            regsub "^i:/WORK/${top}/" $key "" key
            regsub "^u_core/" $key "" key
            set key [string map {\\ ""} $key]
            set ilut($key) $ip
        }
    }
    set n 0
    set miss 0
    foreach rp $refs {
        set rel $rp
        regsub "^r:/WORK/${top}/" $rel "" rel
        set key ""
        if {[regexp {^enqRob_req_(\d+)_bits_r_(\w+?)_reg(\[\d+\])?$} $rel -> k f b]} {
            set key "enqRobBits_reg\[$k\]\[$f\]$b"
        } elseif {[regexp {^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_exceptionVec_(\d+)_reg$} $rel -> k j]} {
            set key "wbDelayedBits_reg\[$k\]\[exceptionVec\]\[$j\]"
        } elseif {[regexp {^delayedNotFlushedWriteBack_delayed_bits_r_(\d+)_(debug_\w+)_reg$} $rel -> k f]} {
            set key "wbDelayedBits_reg\[$k\]\[$f\]"
        } elseif {[regexp {^delayedNotFlushedWriteBackNums_delayed_bits_r_(\d+)_reg(\[\d+\])?$} $rel -> k b]} {
            set key "wbNumsBits_reg\[$k\]$b"
        } elseif {[regexp {^delayedNotFlushedWriteBackNums_delayed_bits_r_reg(\[\d+\])?$} $rel -> b]} {
            set key "wbNumsBits_reg\[0\]$b"
        } elseif {[regexp {^redirectGen_io_oldestExuRedirect_bits_r_(\w+?)_reg(\[\d+\])?$} $rel -> f b]} {
            set key "oldestExuRedirectBits_reg\[$f\]$b"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_level_reg$} $rel]} {
            set key "s3_s5_redirect_level_reg"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_robIdx_flag_reg$} $rel]} {
            set key "s3_s5_redirect_robFlag_reg"
        } elseif {[regexp {^s3_s5_redirect_next_bits_r_robIdx_value_reg(\[\d+\])?$} $rel -> b]} {
            set key "s3_s5_redirect_robValue_reg$b"
        } elseif {[regexp {^s3_s5_redirect_next_valid_last_REG_reg$} $rel]} {
            set key "s3_s5_redirect_valid_reg"
        } elseif {[regexp {^s2_s4_redirect_next_valid_last_REG_reg$} $rel]} {
            set key "s2_s4_redirect_valid_reg"
        } elseif {[regexp {^decodeBufBits_(\d+)_foldpc_reg(\[\d+\])?$} $rel -> k b]} {
            set key "decodeBufBits_reg\[$k\]\[foldpc\]$b"
        } elseif {[regexp {^io_perf_(\d+)_value_REG_reg(\[\d+\])?$} $rel -> k b]} {
            set key "perfStage0_reg\[$k\]$b"
        } elseif {[regexp {^io_perf_(\d+)_value_REG_1_reg(\[\d+\])?$} $rel -> k b]} {
            set key "perfStage1_reg\[$k\]$b"
        }
        if {$key eq "" || ![info exists ilut($key)]} { incr miss; continue }
        if {[catch {set_user_match $rp $ilut($key)} msg]} {
            puts "CTRLBLOCK_PIN_FAIL: $rp <-> $ilut($key) ($msg)"
        } else {
            incr n
            unset ilut($key)
        }
    }
    puts "CTRLBLOCK_PINS: $n pinned, $miss ref-side un-mappable (见 unmatched_full.rpt)"
}
ctrlblock_pin_unmatched $top

# rob 内部 deqHitRedirectReg_REG/REG_1 是 firtool 同驱动复制对(Rob.sv 两侧同一份源),
# merge pass 在 ref 侧把 REG 并入 REG_1、impl 侧未并 → impl REG 落单 unmatched。
# 依次尝试: (a) ref 同名 REG 还在(未并)则直接钉; (b) 多对一钉到 ref 幸存者 REG_1。
if {[catch {set_user_match "r:/WORK/$top/rob/deqHitRedirectReg_REG_reg" \
                           "i:/WORK/$top/u_core/rob/deqHitRedirectReg_REG_reg"} m1]} {
    if {[catch {set_user_match "r:/WORK/$top/rob/deqHitRedirectReg_REG_1_reg" \
                               "i:/WORK/$top/u_core/rob/deqHitRedirectReg_REG_reg"} m2]} {
        puts "CTRLBLOCK_PINS: rob deqHitRedirectReg 钉点两式均拒 ($m1 / $m2)"
    } else { puts "CTRLBLOCK_PINS: rob deqHitRedirectReg 多对一钉到 REG_1" }
} else { puts "CTRLBLOCK_PINS: rob deqHitRedirectReg 同名钉上" }
