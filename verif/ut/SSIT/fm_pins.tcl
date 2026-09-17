# SSIT FM 钉点 —— **只消名差**，不约束 ref、不 dont_verify、不扩黑盒、不动黑名单。
# ---------------------------------------------------------------------------
# 为什么需要：SSIT 的 15 个标量寄存器在 golden 里带的是 firtool 展平名，其中好几个
# 名不副实（`s2_ldSsidAllocate_value` 存的其实是 ldpc，不是 ssid；`REG` 是
# lvpred_timeout 的一拍寄存）。可读核按语义重新命名了它们，于是 FM 的按名匹配对不上。
# 三组 1024 项影子数组不在此列：可读核沿用了 golden 的基名 debug_valid/debug_ssid/
# debug_strict，scripts/fm_eq.tcl 的 auto_match_flattened_arrays 会自己配好
# （`debug_ssid_reg[1023][4]` ↔ `debug_ssid_1023_reg[4]`）。
#
# 每一条都是严格 1↔1：同一个次态函数、同一个使能、同一个复位域，只有名字不同。
# 下表逐条列出对应关系与它在 golden 哪一行被赋值，便于复核：
#   resetCounter(L17588)              -> reset_counter        冲刷周期计数器
#   resetStepCounter(L17593)          -> reset_step           冲刷指针
#   REG(L30915)                       -> timeout_q            RegNext(lvpred_timeout)
#   s1_mempred_update_req_valid(L30916) -> s1_valid
#   s1_mempred_update_req_ldpc(L30918)  -> s1_ldpc
#   s1_mempred_update_req_stpc(L30919)  -> s1_stpc
#   s2_mempred_update_req_valid(L30921) -> s2_valid
#   s2_ldSsidAllocate_value(L30923)     -> s2_ldpc            ★名不副实，存的是 ldpc
#   s2_stSsidAllocate_value(L30924)     -> s2_stpc            ★同上
#   s2_loadAssigned(L30925)             -> s2_load_assigned
#   s2_storeAssigned(L30926)            -> s2_store_assigned
#   s2_loadOldSSID(L30927)              -> s2_load_old_ssid
#   s2_storeOldSSID(L30928)             -> s2_store_old_ssid
#   s2_loadStrict(L30929)               -> s2_load_strict
# （`state` 两侧同名，不用钉。）
#
# 做法与 scripts/fm_eq.tcl 的 auto_match_flattened_arrays 同构：从
# report_unmatched_points **现场读回**真实路径再配对，不把层次路径写死在脚本里。
# 若 FM 自己已经把它们配上了，本脚本什么都不会做（打印 0 points pinned）。
# ---------------------------------------------------------------------------
array set _ssit_rename {
  resetCounter                  reset_counter
  resetStepCounter              reset_step
  REG                           timeout_q
  s1_mempred_update_req_valid   s1_valid
  s1_mempred_update_req_ldpc    s1_ldpc
  s1_mempred_update_req_stpc    s1_stpc
  s2_mempred_update_req_valid   s2_valid
  s2_ldSsidAllocate_value       s2_ldpc
  s2_stSsidAllocate_value       s2_stpc
  s2_loadAssigned               s2_load_assigned
  s2_storeAssigned              s2_store_assigned
  s2_loadOldSSID                s2_load_old_ssid
  s2_storeOldSSID               s2_store_old_ssid
  s2_loadStrict                 s2_load_strict
}

proc _ssit_pin_renamed_regs { } {
    upvar #0 _ssit_rename map
    redirect -variable um_txt {report_unmatched_points}

    array set impl_lut {}
    set refs {}
    foreach line [split $um_txt "\n"] {
        if {[regexp {Ref\s+DFF\S*\s+(r:\S+)} $line -> rpath]} {
            lappend refs $rpath
        } elseif {[regexp {Impl\s+DFF\S*\s+(i:\S+)} $line -> ipath]} {
            set impl_lut([file tail $ipath]) $ipath
        }
    }

    set n 0
    set miss 0
    foreach rpath $refs {
        set leaf [file tail $rpath]
        # 叶名形如 name_reg 或 name_reg[3]（多位寄存器逐位一个比较点）
        if {![regexp {^(.*)_reg((?:\[\d+\])*)$} $leaf -> stem bits]} { continue }
        if {![info exists map($stem)]} { continue }
        set want "$map($stem)_reg$bits"
        if {![info exists impl_lut($want)]} {
            puts "SSIT_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        if {[catch {set_user_match $rpath $impl_lut($want)} msg]} {
            puts "SSIT_PINS_FAIL: $rpath <-> $impl_lut($want) ($msg)"
            incr miss
        } else {
            puts "SSIT_PINS: $rpath <-> $impl_lut($want)"
            unset impl_lut($want)
            incr n
        }
    }
    if {$n > 0} { match }
    puts "SSIT_PINS: $n points pinned, $miss missed"
}

if {[catch {_ssit_pin_renamed_regs} _ssit_err]} {
    puts "SSIT_PINS: 跳过（$_ssit_err）"
}
