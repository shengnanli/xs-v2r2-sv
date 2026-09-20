# =============================================================================
# WBArbiter 家族「匹配后」钉点：把 N=1 变体里 golden 与重写核**同为死位**的两个
# 未读寄存器一一配对。由 ut_common.mk 作为 FM_PIN_TCL 传入（首次 match 之后执行）。
#
# 为什么需要（实测，不是推测）
# ----------------------------
# 本轮 55 个目标一轮跑完（evidence/<commit>/），13 个 WBArbiter 里 9 个
# native+strict 双 SUCCEEDED、unread 0；剩下 4 个**恰好是 N=1 的那四个**
# （WBArbiter_3 / _38 / _58 / _66），四份 unread_points.txt 形状逐字相同：
#
#     ref  r:/WORK/<top>/cancelCounter_0_reg[0]
#     ref  r:/WORK/<top>/hasFull_reg
#     impl i:/WORK/<top>/u_core/cancel_cnt_q_reg[0][0]
#     impl i:/WORK/<top>/u_core/has_full_q_reg
#
# native 判 SUCCEEDED（failing 0 / unverified 0 / aborted 0 / 比较点 unmatched 0(0)），
# 卡住 strict 的只有这 2(2) 个 **unmatched unread** 点。
#
# 为什么两侧都死（与 tb 判据同源，不是为签核现编的理由）
# ----------------------------------------------------
# scripts/wbarbiter_reachability.py 把 golden 的次态方程原样搬进脚本穷举可达状态，
# N=1 的结论是**可达状态只有 1 个（全 0）**：只有一路请求 ⇒ 它永远是最高优先级 ⇒
# in_ready 恒 1 ⇒ stalled 恒 0 ⇒ cancelCounter 永不自增、isFull 永不置位、
# hasFull 永不置位。也就是说这 5 位是 **golden 自己的死逻辑**，重写核照抄
# （rtl/backend/WBArbiter.sv 的 xs_WBArbiter_core，不因 N=1 而裁剪），于是对称死。
# 这条结论在本轮之前就写进了 UT 的覆盖判据（README「N=1: 可达状态只有 1 个」），
# 不是看见 unread 之后才补的说法。
#
# 5 位里为什么只剩 2 位是 unread 点：其余 3 位（cancelCounter 的 bit1/bit2、isFull）
# 被 FM 自己的常量折叠吃掉了，两侧一起消失，所以既不是比较点也不是未读点。
# 这也是本轮 passing 预测在这 4 个目标上落空的原因（见下面的诚实交代）。
#
# ★诚实交代：本文件修的是 strict 的 unread 卡点，不是修预测★
# docs/fubusy_wbarb_passing_prediction.tsv 对这 4 个目标预登记的 passing 是
# 7 / 15 / 14 / 12（模型 = 触发器位数 + 顶层 output 位数），实测是 2 / 10 / 9 / 7，
# 逐个差 5 —— 那 5 位就是上面说的 N=1 死寄存器，模型把它们算成了比较点。
# 预测**不改**，差异按 fail 记在 docs 与汇报里；本文件只做配对这一步。
#
# fm_eq.tcl 的 auto_match_flattened_arrays 为什么配不上
# ----------------------------------------------------
# 它读的是 report_unmatched_points 的**默认**报告，默认报告不含 unread 类
# （必须显式 -status unread）；而且两侧词干本就不同
# （cancelCounter_0 vs cancel_cnt_q[0]、hasFull vs has_full_q），
# 按名/按形状都无从下手。
#
# ★fail-closed★
# set_user_match 对**不存在的名字不报错**（本仓实测），所以「钉了 N 条」本身
# 什么都不证明。判据四层，与 verif/ut/RenameBuffer/fm_pins.tcl 同一套：
#   1. 每条 ref 未读点必须命中**两条结构规则之一**；形状不符即 exit 3
#      （别的未读点不许被这段代码顺手吞掉 —— 情况变了就停下来诊断，不要盲钉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防凭空造点）；
#   3. 同一条 impl 路径不许被钉两次（防多钉抢点）；
#   4. 钉点条数必须等于 impl 侧未读点数（防漏钉）。
# 终局判据在外层：fm_eq.tcl 最后一次 match 之后重新导出 unread_points.txt，
# validator 要求 unread 归 0；而「加强有没有真去比」要看 passing 是否 +2
# （2→4 / 10→12 / 9→11 / 7→9），那一步要 vmucp 白名单。
#
# N>=2 的 9 个变体在这里**没有未读点**，走 "nothing to pin" 分支原样通过 ——
# 同一个 UT 目录一份 fm_pins.tcl 服务 13 个 target，不能假设一定有活干。
#
# ★puts 一律用 ASCII★：Formality 的 fm.log 不是 UTF-8，中文 puts 会变成一串 ?。
# 注释留中文没问题（读的是源文件），但**进日志的字**必须 ASCII。
#
# 本文件在受限 safe interp 里执行（sidecar_pin_source），不依赖父层变量：
# 顶层名从未读点路径里现取，不用 $top。
# =============================================================================

proc wbarb_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        puts "WBARBITER_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
        exit 3
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [wbarb_unread reference]
set _impl [wbarb_unread implementation]

if {[llength $_ref] == 0 && [llength $_impl] == 0} {
    puts "WBARBITER_PINS: no unmatched unread points, nothing to pin"
} else {
    set _pinned 0
    set _used   {}
    set _nA 0 ; set _nB 0
    foreach r $_ref {
        set i ""
        # A. cancelCounter_<k>_reg[<b>]  <->  u_core/cancel_cnt_q_reg[<k>][<b>]
        if {[regexp {^r:(/WORK/[^/]+)/cancelCounter_(\d+)_reg\[(\d+)\]$} $r -> scope idx bit]} {
            set i "i:$scope/u_core/cancel_cnt_q_reg\[$idx\]\[$bit\]"
            incr _nA
        # B. hasFull_reg  <->  u_core/has_full_q_reg
        } elseif {[regexp {^r:(/WORK/[^/]+)/hasFull_reg$} $r -> scope]} {
            set i "i:$scope/u_core/has_full_q_reg"
            incr _nB
        } else {
            puts "WBARBITER_PIN_ERROR: unexpected ref unread point $r"
            puts "  only 2 families accepted: cancelCounter_<k>_reg\[<b>\], hasFull_reg"
            puts "  a different shape means something changed -- stop and diagnose, do NOT blind-pin"
            exit 3
        }
        if {[lsearch -exact $_impl $i] < 0} {
            puts "WBARBITER_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
            exit 3
        }
        if {[lsearch -exact $_used $i] >= 0} {
            puts "WBARBITER_PIN_ERROR: impl path pinned twice (over-pinning): $i"
            exit 3
        }
        if {[catch {set_user_match $r $i} _msg]} {
            puts "WBARBITER_PIN_ERROR: set_user_match failed $r <-> $i : $_msg"
            exit 3
        }
        lappend _used $i
        incr _pinned
    }
    if {$_pinned != [llength $_impl]} {
        puts "WBARBITER_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
        exit 3
    }
    puts "WBARBITER_PINS: pinned $_pinned points (cancelCounter $_nA, hasFull $_nB); bijection ok"
}
