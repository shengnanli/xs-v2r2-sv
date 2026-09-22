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
# (2) **`set_user_match` 从不抛 Tcl 异常**：名字存在返回 1；名字不存在返回 0 并往
#     fm.log 写一行行首 `Error:`。所以拿 catch 去数是空的，而本文件 2026-09-20 之前
#     **通篇只有 puts、没有任何中止路径** —— 一个点都没配上也照样跑完、照样绿。
#     现在四道 fail-closed（全在最后一次 set_user_match 之后，返回值那道在循环里）：
#       (1) 每一次 set_user_match 都必须返回 1，否则 error；
#       (2) miss 必须为 0（想配的 impl 点必须真的在未匹配集合里）；
#       (3) ref 侧未匹配未读点总数必须等于期望值（防"多出来一族没人管"）；
#       (4) 配对数必须等于**声明出来的字面整数** 91。
#     ★期望值 91 是机械推导的，不是抄来的数字★：就是上面那 14 个寄存器的位宽之和，
#     逐个从 G1 golden 的 `reg [hi:0] <名>;` 现数（width = hi+1）：
#       resetCounter 20 / resetStepCounter 11 / REG 5 / s1_valid 1 / s1_ldpc 10 /
#       s1_stpc 10 / s2_valid 1 / s2_ldpc 10 / s2_stpc 10 / s2_loadAssigned 1 /
#       s2_storeAssigned 1 / s2_loadOldSSID 5 / s2_storeOldSSID 5 / s2_loadStrict 1
#       = 91（与 2026-09-17 首跑实测的 91(91) 一致）。
#     终局判据仍在下游、也仍然更强：fm.log 行首 `Error:` 计数（按本文件打的
#     SSIT_PIN_BEGIN/END 区间归因，scripts/check_pin_errors.py --marker SSIT_PIN）
#     / match 后 Unmatched 0(0) / 终判 SUCCEEDED 且 failing=0。
#
# (3) ★中止一律用 `error`，不用 `exit`★（本 lane 实测）：本文件跑在
#     `interp create -safe` 的受限子解释器里，而 **Tcl safe interp 隐藏 `exit`**：
#       $i eval {info commands exit}  -> ★空（命令不存在）★
#       $i eval {exit 3}              -> 抛出: invalid command name "exit"
#       $i eval {error "PIN_MISS"}    -> 抛出: PIN_MISS
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

    # 期望配对数（推导见文件头 (2)）：14 个改名寄存器的位宽之和。
    set _expect 91
    # ★标记★：fm.log 里 SSIT_PIN_BEGIN 与 SSIT_PIN_END 之间的行首 `Error:` 才是
    #   本文件钉点失败（scripts/check_pin_errors.py --marker SSIT_PIN）。
    puts "SSIT_PIN_BEGIN SSIT expect=$_expect"

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
        # ★用返回值判成败，不用 catch★：set_user_match 从不抛异常（见文件头 (2)）。
        if {![set_user_match $rpath $impl_lut($want)]} {
            puts "SSIT_PIN_FAIL: set_user_match returned 0 for $rpath"
            error "SSIT_PIN_MISS=$rpath"
        }
        unset impl_lut($want)
        incr n
    }
    puts "SSIT_PIN_END SSIT n=$n miss=$miss expect=$_expect"
    puts "SSIT_PINS_TRIED: ref_unread=[llength $refs] impl_unread=[llength $impls] tried=$n miss=$miss"
    # fail-closed：钉不上/少钉/多出一族，都在这里停住，不是只 puts 一行。
    if {$miss != 0} { error "SSIT_PIN_NO_PARTNER=$miss" }
    if {[llength $refs] != $_expect} {
        puts "SSIT_PIN_ERROR: ref unread points [llength $refs] but expected $_expect"
        error "SSIT_PIN_REF_COUNT=[llength $refs]"
    }
    if {$n != $_expect} {
        puts "SSIT_PIN_ERROR: pinned $n but expected $_expect (sum of the 14 renamed registers widths)"
        error "SSIT_PIN_COUNT=$n"
    }
    if {$n > 0} { match }
}

_ssit_pin_renamed_regs
