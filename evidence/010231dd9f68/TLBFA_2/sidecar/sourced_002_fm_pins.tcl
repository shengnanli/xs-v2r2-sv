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
# set_user_match 对**不存在的名字不报错**（本仓实测：喂完全不存在的路径照样返回 0，
# catch 抓不到），所以"钉了 N 条"本身什么都不证明。本脚本的判据是三层：
#   1. 每条 ref 未读点必须能被**结构规则**解析（形状不符即 exit 3，防止别的未读点
#      被这段代码顺手吞掉）；
#   2. 由 ref 推出的 impl 路径必须**确实出现在实测 impl 未读集合里**（防多钉抢点）；
#   3. 钉点条数必须等于 impl 侧未读点数（防漏钉）。
# 真正的终局判据在外层：fm_eq.tcl 会在最后一次 match 之后重新导出 unread_points.txt，
# validator 要求 unread 归 0 且 passing 增加；钉没钉上、加强有没有真去比，那里见真章。
#
# 本文件在受限 safe interp 里执行（sidecar_pin_source），所以不依赖父层变量：
# 顶层名从未读点路径里现取，不用 $top。
# =============================================================================

proc tlbfa_unread {side} {
    set out {}
    if {[catch {report_unmatched_points -$side -status unread -list} res]} {
        puts "TLBFA_PIN_ERROR: report_unmatched_points -$side -status unread 失败: $res"
        exit 3
    }
    foreach p [lsort -unique $res] { lappend out $p }
    return $out
}

set _ref  [tlbfa_unread reference]
set _impl [tlbfa_unread implementation]

if {[llength $_ref] == 0 && [llength $_impl] == 0} {
    puts "TLBFA_PINS: 没有未匹配的未读点，无需钉点"
} else {
    set _pinned 0
    foreach r $_ref {
        # ref 形如 r:/WORK/<top>/reqVpn[_N]_reg[b]
        if {![regexp {^r:(/WORK/[^/]+)/reqVpn(?:_(\d+))?_reg\[(\d+)\]$} $r -> scope port bit]} {
            puts "TLBFA_PIN_ERROR: 未预期的 ref 未读点 $r"
            puts "  本脚本只认 reqVpn 高位死位；出现别的形状说明情况变了，停下来诊断，不要盲钉。"
            exit 3
        }
        if {$port eq ""} { set port 0 }
        set i "i:$scope/u_core/g_port\[$port\].req_vpn_q_reg\[$bit\]"
        if {[lsearch -exact $_impl $i] < 0} {
            puts "TLBFA_PIN_ERROR: ref $r 推出的 impl 路径不在实测未读集合里：$i"
            exit 3
        }
        if {[catch {set_user_match $r $i} _msg]} {
            puts "TLBFA_PIN_ERROR: set_user_match 失败 $r <-> $i : $_msg"
            exit 3
        }
        incr _pinned
    }
    if {$_pinned != [llength $_impl]} {
        puts "TLBFA_PIN_ERROR: 钉了 $_pinned 条，impl 侧未读点却有 [llength $_impl] 个 —— 不是双射"
        exit 3
    }
    puts "TLBFA_PINS: 钉了 $_pinned 对 reqVpn 死位（ref [llength $_ref] / impl [llength $_impl]），双射成立"
    puts "TLBFA_PINS: 终局判据在外层——最后一次 match 后 unread 必须归 0，且 passing 必须增加 $_pinned"
}
