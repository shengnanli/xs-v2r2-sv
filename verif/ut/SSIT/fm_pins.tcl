# SSIT FM 钉点 —— **只消名差**，不约束 ref、不放宽任何 appvar、不扩黑盒。
# ---------------------------------------------------------------------------
# 为什么需要：SSIT 的 15 个标量寄存器在 golden 里带的是 firtool 展平名，其中好几个
# 名不副实（`s2_ldSsidAllocate_value` 存的其实是 ldpc，不是 ssid；`REG` 是
# lvpred_timeout 的一拍寄存）。可读核按语义重新命名了它们，于是 FM 的按名匹配对不上。
# 实测（2026-09-17 首跑）：恰好 **91(91)** 个 unmatched unread 点，逐位数正好是
# 下面这 15 个寄存器的位宽之和（20+11+5+1+10+10+1+10+10+1+1+5+5+1=91）。
#
# 三组 1024 项影子数组**不在此列**：可读核沿用了 golden 的基名 debug_valid/
# debug_ssid/debug_strict，scripts/fm_eq.tcl 的 auto_match_flattened_arrays 按
# `<名>_<i>[_<j>]_reg` 规则自己配好（debug_ssid_reg[1023][4] <-> debug_ssid_1023_reg[4]）。
#
# 对应关系（括号里是 golden 中被赋值的行号，便于复核）：
#   resetCounter(L17588)                -> reset_counter        冲刷周期计数器
#   resetStepCounter(L17593)            -> reset_step           冲刷指针
#   REG(L30915)                         -> timeout_q            RegNext(lvpred_timeout)
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
# ★两条实测约束，照它们写★
# (1) **本文件跑在 sidecar 的 safe child interp 里**，可用命令是白名单里那十几个
#     （见 scripts/sidecar/fm_native_emit.tcl 的 sidecar_pin_source）。
#     `redirect` 不在白名单，`file` 也被 safe interp 藏了 —— 2026-09-17 首跑就是
#     栽在这里：本文件上一版用 `redirect -variable ... {report_unmatched_points}`
#     抓文本，fm.log 里只留下一行 `SSIT_PINS: 跳过（invalid command name "redirect"）`，
#     91 个点一个没钉，而整轮照样跑到底（钉点失败不会让 FM 停）。
#     所以这里改用白名单里的 `report_unmatched_points ... -list`：它直接返回点名列表，
#     不需要 redirect；叶名用字符串切，不用 `file tail`。
# (2) **`set_user_match` 对不存在的名字不报错**（返回 0，catch 抓不到）。所以
#     「钉满 N 个」这类自报数字**不是**任何形式的通过判据，下面那行 puts 只是给人看的
#     线索。真正的判据只有三条，都在 fm.log 里、由 fm_verdict.py 判：
#       FM-036 行数为 0 / match 后 Unmatched 0(0) / 终判 SUCCEEDED 且 failing=0。
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

# safe interp 里没有 `file tail`，自己切最后一段。
proc _ssit_leaf {p} {
    set i [string last "/" $p]
    if {$i < 0} { return $p }
    return [string range $p [expr {$i + 1}] end]
}

proc _ssit_pin_renamed_regs { } {
    upvar #0 _ssit_rename map

    # 现场读回**真实点名**再配对，不把层次路径写死在脚本里。
    set refs  [report_unmatched_points -reference      -status unread -list]
    set impls [report_unmatched_points -implementation -status unread -list]

    array set impl_lut {}
    foreach ip $impls { set impl_lut([_ssit_leaf $ip]) $ip }

    set n 0
    set miss 0
    foreach rpath $refs {
        set leaf [_ssit_leaf $rpath]
        # 叶名形如 name_reg 或 name_reg[3]（多位寄存器逐位一个点）
        if {![regexp {^(.*)_reg((?:\[\d+\])*)$} $leaf -> stem bits]} { continue }
        if {![info exists map($stem)]} { continue }
        set want "$map($stem)_reg$bits"
        if {![info exists impl_lut($want)]} {
            puts "SSIT_PINS_MISS: $rpath 想配 $want，impl 侧未匹配点里没有它"
            incr miss
            continue
        }
        set_user_match $rpath $impl_lut($want)
        unset impl_lut($want)
        incr n
    }
    if {$n > 0} { match }
    # 只是线索，不是判据（见文件头 (2)）。
    puts "SSIT_PINS_TRIED: ref_unread=[llength $refs] impl_unread=[llength $impls] tried=$n miss=$miss"
}

_ssit_pin_renamed_regs
