# =============================================================================
# TLBNonBlock 家族「匹配后」钉点：把 golden 与重写核里**同为死位**的未读寄存器
# 一一配对。由 ut_common.mk 作为 FM_PIN_TCL 传入（在首次 match 之后执行）。
#
# 为什么必须钉（实测，不是推测）
# ------------------------------
# 逐 lane 消寄存器补齐之后，TLBNonBlock_2 的 strict 跑成
# native SUCCEEDED / failing 0 / unverified 0 / unmatched 比较点 0，
# 剩下的唯一卡点是**两侧数量相等但名字对不上**的 unmatched unread 点。
# 按 fm_eq.tcl 里写死的那条通用判断：unmatched unread 单开 verify_matched_unread
# **必然空转**（加强只作用于 matched unread 点，FM 没配上就没有对象）。
# 所以顺序是：**先配对（本文件），再加强（vmucp 白名单）**。
#
# 点是哪些、为什么两侧都死
# ------------------------------
#  A. first_issue 打拍。golden 里是匿名 RegNext，firtool 命名成 r / r_1 / r_2 ...
#     每条**有 debug_isFirstIssue 输入端口**的 lane 两个，按 lane 顺序连号：
#         r_{2i}   <- io_requestor_<i>_req_bits_debug_isFirstIssue
#         r_{2i+1} <- 同一个信号（Chisel 里写了两遍）
#     （golden TLBNonBlock.sv:3586-3633 / _1:1911-1928 / _2:1333-1334 逐行核过。）
#     它们唯一的去处是 XSPerfAccumulate，firtool 把统计消掉之后就没有读者了 ——
#     两侧同为死位。重写核照抄这对冗余寄存器（合并成一个是抹平 golden 的结构）。
#     ★r_{2i} 与 r_{2i+1} 值恒等、使能相同，所以 A 族的配对顺序没有自由度问题：
#       任取一种一一对应都是同一个证明。这里固定取 偶数->first_issue_r、
#       奇数->first_issue_r2，只为可复现。★
#
#  B. result_ok_last 的 0 号。golden 命名是 result_ok_last_REG（无后缀）/
#     _REG_1 / _REG_2 ...，重写核是数组 result_ok_last_reg[i]。
#     FM 自己能把 `_REG_<n>` 配到 `[n]`（后缀与下标同号），**唯独无后缀的 0 号配不上**。
#     它在没有 perf 端口的变体里两侧都没有读者（perf 是它唯一的消费者）。
#
# fm_eq.tcl 的 auto_match_flattened_arrays 配不上 A 族：ref 词干是 `r`，
# impl 词干是 `first_issue_r{,2}`，没有任何公共结构可依。
#
# ★fail-closed★
# set_user_match 对**不存在的名字不报错**，所以「钉了 N 条」本身什么都不证明。
# 本脚本判据四层（与 verif/ut/RenameBuffer/fm_pins.tcl 同形）：
#   1. 每条 ref 未读点必须能被上面两族之一解析；形状不符即 exit 3
#      （情况变了就停下来诊断，不要盲钉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**；
#   3. 同一条 impl 路径不许被钉两次；
#   4. 钉点条数必须等于 impl 侧未读点数（双射，不许漏钉）。
# 终局判据在外层：validator 要求 unread 归 0，而「加强有没有真去比」要看 passing
# 是否按点数增加 —— 那一步要 vmucp 白名单。
#
# ★puts 一律 ASCII★：Formality 的 fm.log 不是 UTF-8，中文 puts 落进日志变问号。
# =============================================================================

proc tlbnb_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        puts "TLBNONBLOCK_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
        exit 3
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [tlbnb_unread reference]
set _impl [tlbnb_unread implementation]

if {[llength $_ref] == 0 && [llength $_impl] == 0} {
    puts "TLBNONBLOCK_PINS: no unmatched unread points, nothing to pin"
} else {
    set _pinned 0
    set _used   {}
    set _nA 0 ; set _nB 0
    foreach r $_ref {
        set i ""
        # A. r_reg / r_<n>_reg  ->  first_issue_r[n/2] (n even) / first_issue_r2[n/2] (n odd)
        if {[regexp {^r:(/WORK/[^/]+)/r_reg$} $r -> scope]} {
            set i "i:$scope/u_core/first_issue_r_reg\[0\]"
            incr _nA
        } elseif {[regexp {^r:(/WORK/[^/]+)/r_(\d+)_reg$} $r -> scope n]} {
            set lane [expr {$n / 2}]
            if {[expr {$n % 2}] == 0} {
                set i "i:$scope/u_core/first_issue_r_reg\[$lane\]"
            } else {
                set i "i:$scope/u_core/first_issue_r2_reg\[$lane\]"
            }
            incr _nA
        # B. result_ok_last_REG_reg (no suffix = lane 0) -> result_ok_last_reg[0]
        } elseif {[regexp {^r:(/WORK/[^/]+)/result_ok_last_REG_reg$} $r -> scope]} {
            set i "i:$scope/u_core/result_ok_last_reg\[0\]"
            incr _nB
        } else {
            puts "TLBNONBLOCK_PIN_ERROR: unexpected ref unread point $r"
            puts "  only 2 families accepted: first_issue RegNext (r / r_<n>), result_ok_last_REG (lane 0)"
            puts "  a different shape means something changed -- stop and diagnose, do NOT blind-pin"
            exit 3
        }
        if {[lsearch -exact $_impl $i] < 0} {
            puts "TLBNONBLOCK_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
            exit 3
        }
        if {[lsearch -exact $_used $i] >= 0} {
            puts "TLBNONBLOCK_PIN_ERROR: impl path pinned twice (over-pinning): $i"
            exit 3
        }
        if {[catch {set_user_match $r $i} _msg]} {
            puts "TLBNONBLOCK_PIN_ERROR: set_user_match failed $r <-> $i : $_msg"
            exit 3
        }
        lappend _used $i
        incr _pinned
    }
    if {$_pinned != [llength $_impl]} {
        puts "TLBNONBLOCK_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
        exit 3
    }
    puts "TLBNONBLOCK_PINS: pinned $_pinned pairs (A first_issue $_nA / B result_ok_last lane0 $_nB)"
    puts "TLBNONBLOCK_PINS: ref [llength $_ref] / impl [llength $_impl] -- bijection holds, no duplicate pins"
    puts "TLBNONBLOCK_PINS: final criterion is external -- unmatched unread must reach 0 after last match;"
    puts "TLBNONBLOCK_PINS: to actually COMPARE these points a vmucp whitelist entry is still needed"
}
