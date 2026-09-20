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
# set_user_match **从不抛 Tcl 异常**（名字存在返回 1，不存在返回 0 并往 fm.log 写
# 一行行首 `Error:`）。所以旧版那句 `if {[catch {set_user_match ...}]} {... 中止 ...}`
# 是一个**空守卫**：catch 恒为 0，中止路径永远走不到，_pinned 无条件自增 ——
# 连带把后面那道 `$_pinned != [llength $_impl]` 一起架空。
# ★新判据不能建立在旧判据的中间量上★，所以现在改用**返回值**，并另加一道
# 「钉点数 == 声明出来的字面整数」。
#
# ★中止一律用 `error`，不用 `exit`★（本 lane 实测）：本文件在 sidecar 下跑在
# `interp create -safe` 的受限子解释器里，而 **Tcl safe interp 隐藏 `exit`**：
#     $i eval {info commands exit}  -> ★空（命令不存在）★
#     $i eval {exit 3}              -> 抛出: invalid command name "exit"
#     $i eval {error "PIN_MISS"}    -> 抛出: PIN_MISS
# 旧版那些 `exit 3` 确实会中止，但是靠"这个命令不存在"中止的，不是靠写的人
# 表达的那个意思 —— 与上面那个空守卫是同一族缺陷。
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
        error "TLBNONBLOCK_PIN_REPORT_FAILED=$side"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [tlbnb_unread reference]
set _impl [tlbnb_unread implementation]

# ★期望钉点数的出处（两族分开记，来源不同，别混成一个"总数"）★
#   A 族（first_issue 的匿名 RegNext）：**机械推导自 G1 golden 的寄存器声明**，
#     每 lane 两个（r / r_<n>），复算：
#       grep -cE '^\s*reg\s+r(_[0-9]+)?;' <变体>.sv
#         TLBNonBlock 8 / TLBNonBlock_1 4 / TLBNonBlock_2 2
#   B 族（result_ok_last_REG 无后缀那个 0 号）：**不能只靠数寄存器** ——
#     三个变体 golden 里都有无后缀的 result_ok_last_REG，但它是不是"未匹配未读点"
#     取决于该变体里它有没有读者，数声明看不出来。这里取**已提交 evidence 的实测值**
#     （两个互相独立的 evidence 目录一致）：
#       evidence/88d4f00d0fe1/TLBNonBlock{,_1,_2}/fm.log
#       evidence/522c3fe3d5dd/TLBNonBlock{,_1,_2}/fm.log
#         "pinned 8 pairs (A first_issue 8 / B result_ok_last lane0 0)"   -> B 0
#         "pinned 4 pairs (A first_issue 4 / B result_ok_last lane0 0)"   -> B 0
#         "pinned 3 pairs (A first_issue 2 / B result_ok_last lane0 1)"   -> B 1
#   ⇒ 期望总数 = A + B = 8 / 4 / 3。
#   ★这就是这道守卫的意义★：哪天 B 族变了，这里当场红，而不是无声地少钉一个。
# 变体名从未读点路径里现取（本文件不依赖父层 $top，见文件头）。
if {[llength $_ref] == 0} {
    puts "TLBNONBLOCK_PIN_ERROR: no reference unread points at all -- expected first_issue RegNext dead bits"
    error "TLBNONBLOCK_PIN_NO_REF"
}
if {![regexp {^r:/WORK/([^/]+)/} [lindex $_ref 0] -> _design]} {
    puts "TLBNONBLOCK_PIN_ERROR: cannot read design name out of [lindex $_ref 0]"
    error "TLBNONBLOCK_PIN_NO_DESIGN"
}
switch -exact -- $_design {
    TLBNonBlock   { set _expect 8 }
    TLBNonBlock_1 { set _expect 4 }
    TLBNonBlock_2 { set _expect 3 }
    default       { set _expect -1 }
}
if {$_expect < 0} {
    puts "TLBNONBLOCK_PIN_ERROR: unknown variant $_design -- record its expected pin count first"
    error "TLBNONBLOCK_PIN_UNKNOWN_VARIANT=$_design"
}
# ★标记★：fm.log 里 TLBNONBLOCK_PIN_BEGIN 与 _END 之间的行首 `Error:` 才是本文件
#   钉点失败（scripts/check_pin_errors.py --marker TLBNONBLOCK_PIN）。
puts "TLBNONBLOCK_PIN_BEGIN $_design expect=$_expect"
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
        error "TLBNONBLOCK_PIN_SHAPE=$r"
    }
    if {[lsearch -exact $_impl $i] < 0} {
        puts "TLBNONBLOCK_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
        error "TLBNONBLOCK_PIN_NOT_MEASURED=$i"
    }
    if {[lsearch -exact $_used $i] >= 0} {
        puts "TLBNONBLOCK_PIN_ERROR: impl path pinned twice (over-pinning): $i"
        error "TLBNONBLOCK_PIN_DUP=$i"
    }
    # ★用返回值判成败，不用 catch★：set_user_match 从不抛 Tcl 异常（见文件头），
    # 旧版的中止路径永远走不到，_pinned 无条件自增，连带把下面那道双射守卫一起架空。
    if {![set_user_match $r $i]} {
        puts "TLBNONBLOCK_PIN_FAIL: set_user_match returned 0 for $r <-> $i"
        error "TLBNONBLOCK_PIN_MISS=$r"
    }
    lappend _used $i
    incr _pinned
}
puts "TLBNONBLOCK_PIN_END $_design n=$_pinned miss=0 expect=$_expect"
# fail-closed 三道，全在最后一次 set_user_match **之后**：
#   (1) 每次调用的返回值必须是 1（在循环里）
#   (2) 双射：钉点数 == impl 侧未读点数（防漏钉）
#   (3) 期望数量：钉点数 == 上面声明出来的字面整数（防"两侧一起漂"）
if {$_pinned != [llength $_impl]} {
    puts "TLBNONBLOCK_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
    error "TLBNONBLOCK_PIN_BIJECTION=$_pinned"
}
if {$_pinned != $_expect} {
    puts "TLBNONBLOCK_PIN_ERROR: pinned $_pinned but expected $_expect (A first_issue + B result_ok_last lane0)"
    error "TLBNONBLOCK_PIN_COUNT=$_pinned"
}
puts "TLBNONBLOCK_PINS: pinned $_pinned pairs (A first_issue $_nA / B result_ok_last lane0 $_nB)"
puts "TLBNONBLOCK_PINS: ref [llength $_ref] / impl [llength $_impl] -- bijection holds, no duplicate pins"
puts "TLBNONBLOCK_PINS: final criterion is external -- unmatched unread must reach 0 after last match;"
puts "TLBNONBLOCK_PINS: to actually COMPARE these points a vmucp whitelist entry is still needed"
