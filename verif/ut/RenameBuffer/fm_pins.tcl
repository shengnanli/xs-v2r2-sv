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
# set_user_match 对**不存在的名字不报错**（本仓实测：名字存在返回 1，不存在返回 0
# 并往 fm.log 写一行行首 `Error:`，**从不抛 Tcl 异常**）。所以旧版那句
# `if {[catch {set_user_match $r $i} _msg]} {... error ...}` 是一个**空守卫** ——
# catch 恒为 0，中止路径永远走不到，而且随后 `$_pinned != [llength $_impl]`
# 那道"加强"也继承了这个空洞：_pinned 正是在那个永不触发的 catch 之后无条件自增的。
# ★新判据的输入必须独立于被判断的对象★ —— 现在用 set_user_match 的**返回值**。
# 本脚本判据五层：
#   1. 每条 ref 未读点必须能被**三条结构规则之一**解析；形状不符即 error
#      （防止别的未读点被这段代码顺手吞掉 —— 情况变了就停下来诊断，不要盲钉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防凭空造点）；
#   3. 同一条 impl 路径不许被钉两次（防多钉抢点）；
#   4. **每一次 set_user_match 都必须返回 1**（真的配上了），否则 error；
#   5. 钉点条数必须同时等于 impl 侧未读点数**和**一个声明出来的期望数量
#      `_expect`（字面整数，钉死）—— 前者防漏钉，后者防"两侧一起漂"。
#
# ★_expect 是机械推导的，不是抄来的数字★（本 lane 从 G1 golden 现数）：
#   A  5 点  golden `reg deqPtrVec_<i>_flag;`   i=1..5            -> 5
#   B 40 点  golden `reg [7:0] deqPtrVec_<i>_value;` i=1..5       -> 5 × 8 = 40
#   C  6 点  golden `reg [7:0] io_toVecExcpMod_logicPhyRegMap_<j>_bits_preg_r;`
#            j=0..5，输出端口只有 7 位，bit7 无读出路径             -> 6
#   合计 51。复算：
#     grep -cE '^\s*reg\s+(\[[0-9]+:0\]\s+)?deqPtrVec_[1-9][0-9]*_(flag|value);' RenameBuffer.sv  -> 10
#     grep -cE 'io_toVecExcpMod_logicPhyRegMap_[0-9]+_bits_preg_r;'              RenameBuffer.sv  -> 6
#
# ★中止一律用 `error`，不用 `exit`★（本 lane 实测）：本文件在 sidecar 下跑在
# `interp create -safe` 建的受限子解释器里，而 **Tcl safe interp 隐藏 `exit`**：
#     $i eval {info commands exit}  -> ★空（命令不存在）★
#     $i eval {exit 3}              -> 抛出: invalid command name "exit"
#     $i eval {error "PIN_MISS"}    -> 抛出: PIN_MISS
# 旧版那些 `exit 3` 确实会中止，但**是靠"这个命令不存在"中止的**，不是靠写的人
# 表达的那个意思 —— 与上面那个空守卫是同一族缺陷。
# 真正的终局判据在外层：fm_eq.tcl 在最后一次 match 之后重新导出 unread_points.txt，
# validator 要求 unread 归 0；而「加强有没有真去比」要看 passing 是否 +51
# （5825 → 5876）—— 那一步要 vmucp 白名单，归 reviewer 加，不在本文件。
#
# ★puts 一律用 ASCII★：Formality 的 fm.log 不是 UTF-8，中文 puts 落进日志会变成一串 ?
# （本轮实测：钉点自报那四行在 fm.log 里全成了问号）。注释留中文没问题（读的是源文件），
# 但**进日志的字**必须 ASCII —— 日志是给 reviewer 看的证据。
#
# 本文件在受限 safe interp 里执行（sidecar_pin_source），所以不依赖父层变量：
# 顶层名从未读点路径里现取，不用 $top。
# =============================================================================

proc rab_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        error "RENAMEBUFFER_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

# 期望钉点数：机械推导自 G1 golden 的寄存器声明（见文件头「_expect 是机械推导的」）。
set _expect 51

set _ref  [rab_unread reference]
set _impl [rab_unread implementation]

# ★标记★：fm.log 里 RENAMEBUFFER_PIN_BEGIN 与 _END 之间的行首 `Error:` 才是本文件
#   钉点失败（scripts/check_pin_errors.py --marker RENAMEBUFFER_PIN）。
puts "RENAMEBUFFER_PIN_BEGIN RenameBuffer expect=$_expect"
# ★不再有"没有未读点就啥也不做"这条 fail-open 支路★：期望值是 51，
#   一个都发现不了同样说明前提变了，照样要停下来诊断。
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
        puts "RENAMEBUFFER_PIN_ERROR: unexpected ref unread point $r"
        puts "  only 3 families accepted: deqPtrVec_1..5 flag/value, toVecExcpMod preg bit7"
        puts "  a different shape means something changed -- stop and diagnose, do NOT blind-pin"
        error "RENAMEBUFFER_PIN_SHAPE=$r"
    }
    if {[lsearch -exact $_impl $i] < 0} {
        puts "RENAMEBUFFER_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
        error "RENAMEBUFFER_PIN_NOT_MEASURED=$i"
    }
    if {[lsearch -exact $_used $i] >= 0} {
        puts "RENAMEBUFFER_PIN_ERROR: impl path pinned twice (over-pinning): $i"
        error "RENAMEBUFFER_PIN_DUP=$i"
    }
    # ★用返回值，不用 catch★：set_user_match 从不抛异常（见文件头），
    # 旧版的中止路径永远走不到，_pinned 也就无条件自增。
    if {![set_user_match $r $i]} {
        puts "RENAMEBUFFER_PIN_FAIL: set_user_match returned 0 for $r <-> $i"
        error "RENAMEBUFFER_PIN_MISS=$r"
    }
    lappend _used $i
    incr _pinned
}
puts "RENAMEBUFFER_PIN_END RenameBuffer n=$_pinned miss=0 expect=$_expect"
# fail-closed 三道，全在最后一次 set_user_match **之后**：
#   (1) 双射：钉点数 == impl 侧未读点数（防漏钉）
#   (2) 期望数量：钉点数 == 声明出来的字面整数 51
#   (3) 每次调用的返回值（在循环里，见上）
if {$_pinned != [llength $_impl]} {
    puts "RENAMEBUFFER_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
    error "RENAMEBUFFER_PIN_BIJECTION=$_pinned"
}
if {$_pinned != $_expect} {
    puts "RENAMEBUFFER_PIN_ERROR: pinned $_pinned but expected $_expect (51 = 5 flag + 40 value + 6 preg bit7)"
    error "RENAMEBUFFER_PIN_COUNT=$_pinned"
}
puts "RENAMEBUFFER_PINS: pinned $_pinned pairs (A deqPtr flag $_nA / B deqPtr value $_nB / C vecExcp preg bit7 $_nC)"
puts "RENAMEBUFFER_PINS: ref [llength $_ref] / impl [llength $_impl] -- bijection holds, no duplicate pins"
puts "RENAMEBUFFER_PINS: final criterion is external -- unmatched unread must reach 0 after last match;"
puts "RENAMEBUFFER_PINS: to actually COMPARE these $_pinned points a vmucp whitelist entry is still needed (passing 5825 -> 5876)"
