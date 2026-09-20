# =============================================================================
# TLBFA 家族「匹配后」钉点：把 golden 与重写核里**同为死位**的 reqVpn 高 11 位
# 逐位一一配对。由 ut_common.mk 作为 FM_PIN_TCL 传入（在首次 match 之后执行）。
#
# 为什么必须钉（实测，不是推测）
# ------------------------------
# strict 首跑四个变体都是 native SUCCEEDED / failing 0 / unmatched(比较点) 0，
# 唯一卡点是 11×PORTS 个 **unmatched unread** 点。
# 打开 verify_matched_unread 加强之后**单独复跑过一轮**（TLBFA, commit 513cda8）：
# passing 仍是 8149、未读点仍是 33(33) **unmatched** —— 加强只作用于 **matched**
# unread 点，而这些点 FM 自己没配上，所以加强无事可做，passing 一点没增。
# 按本仓规矩「passing 不增即空转、不算过」，所以必须先把它们配上，加强才有对象。
#
# 这些位为什么两侧都死：reqVpn(= RegNext(vpn)) 的**唯一**读出点是 genPPN，而 genPPN
# 最高只取到 vpn[26:18]（三段 9 位）。golden 里对 reqVpn 的全部切片实测就是
# [26:18] / [17:9] / [8:0] / [3:0] / [2:0]，bit37..27 没有任何读者；重写核同构，
# 所以是**对称死位**，不是哪一侧漏了逻辑。
# （把重写核的 req_vpn_q 收窄成 27 位反而会制造不对称：golden 那 11×PORTS 位会变成
#   golden-only 死位，更难签。照抄 golden 的宽度是对的。）
#
# fm_eq.tcl 的 auto_match_flattened_arrays 配不上它们：那个 proc 读的是
# report_unmatched_points 的**默认**报告，而默认报告不含 unread 类
# （fm_eq.tcl 自己在导出 unread_points.txt 时也注明了这点，必须显式 -status unread）。
#
# ★fail-closed★
# set_user_match **从不抛 Tcl 异常**（本仓实测：名字存在返回 1；名字不存在返回 0
# 并往 fm.log 写一行行首 `Error:`）。所以旧版那句
# `if {[catch {set_user_match $r $i} _msg]} {... 中止 ...}` 是一个**空守卫**：
# catch 恒为 0，中止路径永远走不到，_pinned 无条件自增，
# 连带把后面那道 `$_pinned != [llength $_impl]` 一起架空
# —— ★新判据不能建立在旧判据的中间量上★。现在改用**返回值**。
# 本脚本的判据是四层：
#   1. 每条 ref 未读点必须能被**结构规则**解析（形状不符即 error，防止别的未读点
#      被这段代码顺手吞掉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防多钉抢点）；
#   3. **每一次 set_user_match 都必须返回 1**，否则 error；
#   4. 钉点条数必须同时等于 impl 侧未读点数**和**一个声明出来的期望数量
#      （每变体一个字面整数，推导见下面 switch 处的注释）。
#
# ★中止一律用 `error`，不用 `exit`★（本 lane 实测）：本文件在 sidecar 下跑在
# `interp create -safe` 建的受限子解释器里，而 **Tcl safe interp 隐藏 `exit`**：
#     $i eval {info commands exit}  -> ★空（命令不存在）★
#     $i eval {exit 3}              -> 抛出: invalid command name "exit"
#     $i eval {error "PIN_MISS"}    -> 抛出: PIN_MISS
# 旧版那些 `exit 3` 确实会中止，但是靠"这个命令不存在"中止的，不是靠写的人
# 表达的那个意思 —— 与上面那个空守卫是同一族缺陷。
#
# ★puts 一律用 ASCII★：Formality 的 fm.log 不是 UTF-8，中文 puts 落进日志会变成
# 一串问号（RenameBuffer lane 实测）。注释留中文没问题，进日志的字必须 ASCII。
# 真正的终局判据在外层：fm_eq.tcl 会在最后一次 match 之后重新导出 unread_points.txt，
# validator 要求 unread 归 0 且 passing 增加；钉没钉上、加强有没有真去比，那里见真章。
#
# 本文件在受限 safe interp 里执行（sidecar_pin_source），所以不依赖父层变量：
# 顶层名从未读点路径里现取，不用 $top。
# =============================================================================

proc tlbfa_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        puts "TLBFA_PIN_ERROR: report_unmatched_points -$side -status unread FAILED: $res"
        error "TLBFA_PIN_REPORT_FAILED=$side"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [tlbfa_unread reference]
set _impl [tlbfa_unread implementation]

# ★期望钉点数是机械推导的，不是抄来的数字★（本 lane 从 G1 golden 现数）：
#   每端口 11 个死位 —— golden 里 reqVpn 是 reg [37:0]，而全部读出切片只有
#   [26:18] / [17:9] / [8:0] / [3:0] / [2:0]（复算：
#   `grep -oE 'reqVpn(_[0-9]+)?\[[0-9]+:[0-9]+\]' TLBFA.sv | sort -u`），
#   最高只到 bit26 ⇒ bit37..27 共 11 位无任何读者。
#   端口数 = golden 里 `reg [37:0] reqVpn[_N];` 的条数（复算：
#   `grep -cE '^\s*reg\s+\[[0-9]+:0\]\s+reqVpn(_[0-9]+)?;' <变体>.sv`）：
#     TLBFA 3 / TLBFA_1 4 / TLBFA_2 2 / TLBFA_3 2
#   ⇒ 期望钉点 11 × 端口数 = 33 / 44 / 22 / 22。
# 变体名从未读点路径里现取（本文件不依赖父层 $top，见文件头）。
if {[llength $_ref] == 0} {
    puts "TLBFA_PIN_ERROR: no reference unread points at all -- expected 11 x PORTS reqVpn dead bits"
    error "TLBFA_PIN_NO_REF"
}
if {![regexp {^r:/WORK/([^/]+)/} [lindex $_ref 0] -> _design]} {
    puts "TLBFA_PIN_ERROR: cannot read design name out of [lindex $_ref 0]"
    error "TLBFA_PIN_NO_DESIGN"
}
switch -exact -- $_design {
    TLBFA   { set _expect 33 }
    TLBFA_1 { set _expect 44 }
    TLBFA_2 { set _expect 22 }
    TLBFA_3 { set _expect 22 }
    default { set _expect -1 }
}
if {$_expect < 0} {
    puts "TLBFA_PIN_ERROR: unknown variant $_design -- record its expected pin count first"
    error "TLBFA_PIN_UNKNOWN_VARIANT=$_design"
}
# ★标记★：fm.log 里 TLBFA_PIN_BEGIN 与 _END 之间的行首 `Error:` 才是本文件钉点失败
#   （scripts/check_pin_errors.py --marker TLBFA_PIN）。
puts "TLBFA_PIN_BEGIN $_design expect=$_expect"
set _pinned 0
foreach r $_ref {
    # ref 形如 r:/WORK/<top>/reqVpn[_N]_reg[b]
    if {![regexp {^r:(/WORK/[^/]+)/reqVpn(?:_(\d+))?_reg\[(\d+)\]$} $r -> scope port bit]} {
        puts "TLBFA_PIN_ERROR: unexpected ref unread point $r"
        puts "  only reqVpn high dead bits are accepted; a different shape means something changed"
        puts "  -- stop and diagnose, do NOT blind-pin"
        error "TLBFA_PIN_SHAPE=$r"
    }
    if {$port eq ""} { set port 0 }
    set i "i:$scope/u_core/g_port\[$port\].req_vpn_q_reg\[$bit\]"
    if {[lsearch -exact $_impl $i] < 0} {
        puts "TLBFA_PIN_ERROR: derived impl path not in measured unread set: ref=$r impl=$i"
        error "TLBFA_PIN_NOT_MEASURED=$i"
    }
    # ★用返回值判成败，不用 catch★：set_user_match 从不抛 Tcl 异常（见文件头），
    # 所以旧版 `if {[catch {set_user_match ...}]} {... 中止 ...}` 的中止路径永远走不到，
    # _pinned 也就无条件自增 —— 连带把后面那道 `$_pinned != [llength $_impl]`
    # 一起架空（新判据不能建立在旧判据的中间量上）。
    if {![set_user_match $r $i]} {
        puts "TLBFA_PIN_FAIL: set_user_match returned 0 for $r <-> $i"
        error "TLBFA_PIN_MISS=$r"
    }
    incr _pinned
}
puts "TLBFA_PIN_END $_design n=$_pinned miss=0 expect=$_expect"
# fail-closed 三道，全在最后一次 set_user_match **之后**：
#   (1) 每次调用的返回值必须是 1（在循环里）
#   (2) 双射：钉点数 == impl 侧未读点数（防漏钉）
#   (3) 期望数量：钉点数 == 上面声明出来的字面整数（防"两侧一起漂"）
if {$_pinned != [llength $_impl]} {
    puts "TLBFA_PIN_ERROR: pinned $_pinned but impl has [llength $_impl] unread points -- not a bijection"
    error "TLBFA_PIN_BIJECTION=$_pinned"
}
if {$_pinned != $_expect} {
    puts "TLBFA_PIN_ERROR: pinned $_pinned but expected $_expect (11 dead bits x PORTS)"
    error "TLBFA_PIN_COUNT=$_pinned"
}
puts "TLBFA_PINS: pinned $_pinned reqVpn dead-bit pairs (ref [llength $_ref] / impl [llength $_impl]) -- bijection holds"
puts "TLBFA_PINS: final criterion is external -- unread must reach 0 after last match, and passing must grow by $_pinned"
