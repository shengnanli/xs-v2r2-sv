# =============================================================================
# RenameBuffer「匹配后」钉点：把 golden 与重写核里**同为死位**的 51 个未读寄存器位
# 一一配对。由 ut_common.mk 作为 FM_PIN_TCL 传入（在首次 match 之后执行）。
#
# 为什么必须钉（实测，不是推测）
# ------------------------------
# FM_MERGE_DUP=false 之后 strict 跑成：native SUCCEEDED / passing 5825 / failing 0 /
# unverified 0 / unmatched(比较点) 0(0)，唯一卡点是 51 个 **unmatched unread** 点
# （fm_work/RenameBuffer/unread_points.txt，ref 51 / impl 51）。
# 按 main f55397d 写进 fm_eq.tcl 的那条通用判断：unmatched unread 单开
# verify_matched_unread **必然空转** —— 加强只作用于 **matched** unread 点，
# 而这些点 FM 自己没配上，加强没有对象，passing 一点不增（TLBFA 实测栽过一次）。
# 所以顺序是：**先配对，再加强**。本文件只做配对那一步。
#
# 51 个点是哪些、为什么两侧都死
# ------------------------------
# 三族，逐位对称，无第三族、无落单（实测枚举，不是按名猜的）：
#
#  A. 5 个   ref  deqPtrVec_<i>_flag_reg              (i=1..5)
#            impl u_core/deq_ptr_flag_q_reg[<i>]
#  B. 40 个  ref  deqPtrVec_<i>_value_reg[<b>]        (i=1..5, b=0..7)
#            impl u_core/deq_ptr_value_q_reg[<i>][<b>]
#     死因：deqPtrVec 只有 head(0 号) 有读者 —— numValidEntries(距离) 与
#     deqPtrNext(自增) 都只取 deqPtrVec(0)；提交读口走的是 deqPtrOH 那个 one-hot
#     影子寄存器，不看 deqPtrVec。1..5 号的 flag+value 在**两侧都没有读者**。
#     golden 之所以还留着它们，是 Rab.scala 末尾 `dontTouch(deqPtrVec)`（golden 里
#     留下 data_0_probe / data_1_probe / data_2_probe 这几根悬空线为证）。
#     ★重写核照抄了 golden 的寄存器集合，所以是对称死位★。
#     （把核收窄成只留 head 反而制造不对称：golden 那 45 位会变成 golden-only 死位，
#       更难签 —— 与 TLBFA 收窄 reqVpn 的结论同源。）
#
#  C. 6 个   ref  io_toVecExcpMod_logicPhyRegMap_<j>_bits_preg_r_reg[7]   (j=0..5)
#            impl u_core/vec_excp_preg_q_reg[<j>][7]
#     死因：打拍寄存器存的是 commits.info(j).pdest，**8 位**；而输出端口
#     io_toVecExcpMod_logicPhyRegMap_<j>_bits_preg 只有 **7 位**，golden 写的是
#     `assign ... = ..._preg_r[6:0]` —— bit7 存进去从来没有读出路径。
#     重写核同构（rtl/backend/RenameBuffer.sv §8 注释「★8 位存、7 位出★」），
#     两侧同为死位，bug-for-bug。
#
# fm_eq.tcl 的 auto_match_flattened_arrays 配不上它们：那个 proc 读的是
# report_unmatched_points 的**默认**报告，默认报告不含 unread 类（必须显式
# -status unread）；而且 ref/impl 词干本就不同（deqPtrVec_1_value vs
# deq_ptr_value_q[1]），自动配对无从下手。
#
# ★fail-closed★
# set_user_match 对**不存在的名字不报错**（本仓实测：喂完全不存在的路径照样返回 0，
# catch 抓不到），所以「钉了 N 条」本身什么都不证明。本脚本判据四层：
#   1. 每条 ref 未读点必须能被**三条结构规则之一**解析；形状不符即 exit 3
#      （防止别的未读点被这段代码顺手吞掉 —— 情况变了就停下来诊断，不要盲钉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防凭空造点）；
#   3. 同一条 impl 路径不许被钉两次（防多钉抢点）；
#   4. 钉点条数必须等于 impl 侧未读点数（防漏钉）。
# 真正的终局判据在外层：fm_eq.tcl 在最后一次 match 之后重新导出 unread_points.txt，
# validator 要求 unread 归 0；而「加强有没有真去比」要看 passing 是否 +51
# （5825 → 5876）—— 那一步要 vmucp 白名单，归 reviewer 加，不在本文件。
#
# 本文件在受限 safe interp 里执行（sidecar_pin_source），所以不依赖父层变量：
# 顶层名从未读点路径里现取，不用 $top。
# =============================================================================

proc rab_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        puts "RENAMEBUFFER_PIN_ERROR: report_unmatched_points -$side -status unread 失败: $res"
        exit 3
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [rab_unread reference]
set _impl [rab_unread implementation]

if {[llength $_ref] == 0 && [llength $_impl] == 0} {
    puts "RENAMEBUFFER_PINS: 没有未匹配的未读点，无需钉点"
} else {
    set _pinned 0
    set _used   {}
    set _nA 0 ; set _nB 0 ; set _nC 0
    foreach r $_ref {
        set i ""
        # A. deqPtrVec_<i>_flag_reg
        if {[regexp {^r:(/WORK/[^/]+)/deqPtrVec_(\d+)_flag_reg$} $r -> scope idx]} {
            set i "i:$scope/u_core/deq_ptr_flag_q_reg\[$idx\]"
            incr _nA
        # B. deqPtrVec_<i>_value_reg[<b>]
        } elseif {[regexp {^r:(/WORK/[^/]+)/deqPtrVec_(\d+)_value_reg\[(\d+)\]$} $r -> scope idx bit]} {
            set i "i:$scope/u_core/deq_ptr_value_q_reg\[$idx\]\[$bit\]"
            incr _nB
        # C. io_toVecExcpMod_logicPhyRegMap_<j>_bits_preg_r_reg[<b>]
        } elseif {[regexp {^r:(/WORK/[^/]+)/io_toVecExcpMod_logicPhyRegMap_(\d+)_bits_preg_r_reg\[(\d+)\]$} $r -> scope idx bit]} {
            set i "i:$scope/u_core/vec_excp_preg_q_reg\[$idx\]\[$bit\]"
            incr _nC
        } else {
            puts "RENAMEBUFFER_PIN_ERROR: 未预期的 ref 未读点 $r"
            puts "  本脚本只认三族对称死位（deqPtrVec_1..5 的 flag/value、toVecExcpMod preg 的 bit7）。"
            puts "  出现别的形状说明情况变了，停下来诊断，不要盲钉。"
            exit 3
        }
        if {[lsearch -exact $_impl $i] < 0} {
            puts "RENAMEBUFFER_PIN_ERROR: ref $r 推出的 impl 路径不在实测未读集合里：$i"
            exit 3
        }
        if {[lsearch -exact $_used $i] >= 0} {
            puts "RENAMEBUFFER_PIN_ERROR: impl 路径被钉两次（多钉抢点）：$i"
            exit 3
        }
        if {[catch {set_user_match $r $i} _msg]} {
            puts "RENAMEBUFFER_PIN_ERROR: set_user_match 失败 $r <-> $i : $_msg"
            exit 3
        }
        lappend _used $i
        incr _pinned
    }
    if {$_pinned != [llength $_impl]} {
        puts "RENAMEBUFFER_PIN_ERROR: 钉了 $_pinned 条，impl 侧未读点却有 [llength $_impl] 个 —— 不是双射"
        exit 3
    }
    puts "RENAMEBUFFER_PINS: 钉了 $_pinned 对（A deqPtr flag $_nA / B deqPtr value $_nB / C vecExcp preg bit7 $_nC）"
    puts "RENAMEBUFFER_PINS: ref [llength $_ref] / impl [llength $_impl]，双射成立，无重复钉点"
    puts "RENAMEBUFFER_PINS: 终局判据在外层——最后一次 match 后 unmatched unread 必须归 0；"
    puts "RENAMEBUFFER_PINS: 这 $_pinned 点要真被比，还需 vmucp 白名单（passing 应 5825 -> 5876）"
}
