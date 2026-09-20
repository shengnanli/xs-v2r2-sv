# =============================================================================
# TlbStorageWrapper 家族「匹配后」钉点：把 golden 与重写件里**同为死位**的
# reqVpn 高 11 位逐位一一配对。由 ut_common.mk 作为 FM_PIN_TCL 传入（首次 match 之后执行）。
#
# 为什么必须钉（实测，不是推测）
# ------------------------------
# _2/_3 strict 首跑（commit 3f6dfa6）：native SUCCEEDED / failing 0 / unmatched(比较点) 0，
# passing 8244 / 8240，唯一卡点是 **22 个 unmatched unread** 点（11 位 × 2 个读端口）。
# vmucp 加强只作用于 **matched** unread 点，而这些点 FM 自己没配上 —— 所以加强无事可做。
# 这与 TLBFA 家族当年实测到的完全同形（TLBFA 单开 vmucp 是空转，passing 一点没增，
# 见 verif/ut/TLBFA/fm_pins.tcl 的同一段说明）。
#
# ★这 22 个点正是预测与实测的全部差额★：
#   预测 passing 8266 / 8262（docs/tlbsw23_passing_prediction.md，跑前写定）
#   实测 8244 / 8240，差 22 / 22 —— 22 个死位被算进了 unread 而不是 passing。
#   钉上之后它们成为真比较点，passing 应当正好回到 8266 / 8262。
#   **这是预测模型的一次强校验，不是事后找补**：差额必须恰好等于未读点数。
#
# 这些位为什么两侧都死：reqVpn(= RegNext(vpn)) 的唯一读出点是 genPPN，而 genPPN
# 最高只取到 vpn[26:18]，bit37..27 没有任何读者；重写核同构 ⇒ **对称死位**，
# 不是哪一侧漏了逻辑。（把重写核收窄反而会制造不对称，照抄 golden 宽度是对的。）
#
# 与 TLBFA 版的唯一差别：本目标的顶层是 wrapper，阵列在下一层实例里，
# 所以路径多一级 `<top>/<inst>/`。
#
# 变体 0 / _1 也会 source 到本文件：它们两侧用的都是 golden TLBFA（f40deba 那轮的闭包），
# reqVpn 按名字就配上了，未读集合为空 ⇒ 本脚本打印"无需钉点"后什么也不做。
#
# ★fail-closed★
# set_user_match 对**不存在的名字不报错**（本仓实测），所以"钉了 N 条"本身什么都不证明。
# 判据三层：
#   1. 每条 ref 未读点必须能被**结构规则**解析（形状不符即 exit 3，防止别的未读点被顺手吞掉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防多钉抢点）；
#   3. 钉点条数必须等于 impl 侧未读点数（防漏钉）。
# 终局判据在外层：fm_eq.tcl 最后一次 match 后重新导出 unread_points.txt，
# validator 要求 unread 归 0 且 passing 增加。
# =============================================================================

proc tlbsw_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        error "TLBSW_PIN_ERROR: report_unmatched_points -$side -status unread 失败: $res"
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [tlbsw_unread reference]
set _impl [tlbsw_unread implementation]

if {[llength $_ref] == 0 && [llength $_impl] == 0} {
    puts "TLBSW_PINS: 没有未匹配的未读点，无需钉点"
} else {
    set _pinned 0
    array set _seen_port {}
    foreach r $_ref {
        # ref 形如 r:/WORK/<top>/<inst>/reqVpn[_N]_reg[b]
        if {![regexp {^r:(/WORK/[^/]+/[^/]+)/reqVpn(?:_(\d+))?_reg\[(\d+)\]$} $r -> scope port bit]} {
            error "TLBSW_PIN_ERROR: 未预期的 ref 未读点 $r —— 本脚本只认内层阵列的\
                   reqVpn 高位死位；出现别的形状说明情况变了，停下来诊断，不要盲钉。"
        }
        if {$port eq ""} { set port 0 }
        set i "i:$scope/u_core/g_port\[$port\].req_vpn_q_reg\[$bit\]"
        if {[lsearch -exact $_impl $i] < 0} {
            error "TLBSW_PIN_ERROR: ref $r 推出的 impl 路径不在实测未读集合里：$i"
        }
        if {[catch {set_user_match $r $i} _msg]} {
            error "TLBSW_PIN_ERROR: set_user_match 失败 $r <-> $i : $_msg"
        }
        set _seen_port($port) 1
        incr _pinned
    }
    set _nports [array size _seen_port]
    # ★期望数量是算出来的，不是数出来的★：reqVpn 的死位恒为 bit37..27 共 11 位
    # （genPPN 最高只取到 vpn[26:18]，见上），每个读端口一组。端口数从 ref 未读点里
    # 实测到的端口下标集合取，所以"少了一个端口"会被下面这条当场判红，
    # 而不是顺着实际条数把期望调低——那样等于没有期望。
    if {$_pinned != 11 * $_nports || $_pinned != [llength $_impl]} {
        error "TLBSW_PIN_ERROR: 钉了 $_pinned 条，期望 11×$_nports 位、impl 侧未读点\
               [llength $_impl] 个 —— 三者必须相等，不相等就不是双射"
    }
    puts "TLBSW_PINS: 钉了 $_pinned 对 reqVpn 死位 = 11 位 × $_nports 端口\
（ref [llength $_ref] / impl [llength $_impl]），双射成立"
    puts "TLBSW_PINS: 终局判据在外层——最后一次 match 后 unread 必须归 0，且 passing 必须增加 $_pinned"
}
