# InstrUncache FM 钉点（2026-09-14，PARTIAL 收口簇）——条目锁存地址的死最低位
# ============================================================================
# 症状：signoff-strict 下 native SUCCEEDED / passing 204 / failing 0 /
#       unmatched compare points 0，唯独剩 1(1) unmatched **unread**：
#         Ref   r:/WORK/InstrUncache/entries_0/req_addr_reg[0]
#         Impl  i:/WORK/InstrUncache/entries_0/u_core/req_reg\[addr][0]
#       于是 verdict 卡在 strict_unread!=0。
#
# 这一位是什么：InstrMMIOEntry 锁存 IFU 请求地址（golden InstrMMIOEntry.sv:112
#   `reg [47:0] req_addr;`，154 行 `req_addr <= io_req_bits_addr;`）。锁存之后
#   只有两个读者：
#     InstrMMIOEntry.sv:193  io_resp_bits_data = _GEN_1[req_addr[2:1]]  （选 16 位半字）
#     InstrMMIOEntry.sv:196  io_mmio_acquire_bits_address = {req_addr[47:3], 3'h0}
#   —— MMIO 取指按 8 字节对齐发 Get、按半字选指令，**bit 0 永远没有读者**。
#   可读核照抄同一行为（rtl/frontend/InstrMMIOEntry.sv 的 latched_req_t.addr），
#   所以两侧同为死位，1↔1 严格双射，非本点的未读项为 0。
#
# 为什么 FM 自己配不上：活位 [47:1] 有输出锥，签名分析已经配好了（都在 204 个
#   passing 里）；死位没有输出锥，只能靠名字，而两侧词干不同——
#     golden 逐字段展平  req_addr_reg[0]
#     可读核 packed struct 展平  req_reg\[addr][0]
#   （与 ICacheCtrlUnit 的 ram_reg ↔ slot_reg\[data] 同型。）
#
# 本钉点只消名差：不 dont_verify、不加黑盒、不约束 ref、不跳过任何比对点。
# 钉上之后该点变成 matched-unread；要让 strict 的 unread 归零还需要 target-scoped
# 的 verification_verify_matched_unread_compare_points=true（白名单在
# scripts/fm_eq.tcl，本 UT 的 Makefile 同步打开），届时 FM 会**真去比这一位**，
# passing 应由 204 增至 205。
#
# 本文件被同目录三个变体共用（FM_VARIANTS = InstrMMIOEntry
# Arbiter1_InsUncacheResp InstrUncache）。只对 InstrUncache 生效：其余两个 top
# 下该路径不存在，显式用 $top 门控，避免"钉不上也不报"的静默。
#
# ★为什么是 fm_pins_pre.tcl（首次 match 之前）而不是 fm_pins.tcl（match 之后）★
#   实测：放在 match 之后钉，钉点本身是成功的（unread_points.txt 空、passing
#   204->205），但 fm_verdict.py 仍判 strict_unread!=0。原因是 Formality 的
#   `match` 只在计数**非零**时才打印 "N(M) Unmatched ... unread points" 这一行；
#   第一次 match 打出 1(1)，钉点后的第二次 match 该行直接消失，而
#   fm_verdict.py 的 _unmatch_pair 取的是日志里**最后一次出现**的那行，于是读回
#   的仍是陈旧的 1(1)。这是 fail-closed 方向的误差（把 0 读成 1，不会放过真问题），
#   但会把已经修好的目标判死。在首次 match 之前钉，第一次 match 就报 0，
#   日志里根本不出现该行，采集到 None —— 与 Bku 的 fm_pins_pre.tcl 同一做法。
# ============================================================================

if {$top eq "InstrUncache"} {
  if {[catch {set_user_match "r:/WORK/$top/entries_0/req_addr_reg\[0\]" \
                             "i:/WORK/$top/entries_0/u_core/req_reg\\\[addr\]\[0\]"} _msg]} {
    puts "INSTRUNCACHE_PINS_FAIL: entries_0 req_addr\[0\] -> $_msg"
  } else {
    puts "INSTRUNCACHE_PINS: entries_0 dead req_addr\[0\] 1 / 1 point pinned"
  }
}

# ============================================================================
# InstrMMIOEntry 自己做顶层时的同一位死寄存器（2026-09-20，provefleet3 lane）
# ----------------------------------------------------------------------------
# 上面那段只在 $top eq "InstrUncache" 时生效，路径带 entries_0/ 前缀。
# 但 FM_VARIANTS 里 InstrMMIOEntry 也是一个独立目标，它单独做顶层时**同一位**
# 会原样再出现一次，只是少了 entries_0/ 这一层：
#     Ref   r:/WORK/InstrMMIOEntry/req_addr_reg[0]
#     Impl  i:/WORK/InstrMMIOEntry/u_core/req_reg\[addr][0]
# 实测基线（本 lane，signoff-strict + vmucp=false，fm_work/InstrMMIOEntry）：
#     native SUCCEEDED / passing 204 / failing 0 / unmatched compare points 0
#     / 1 个 unmatched **unread**（就是上面这一对）⇒ verdict PARTIAL(strict_unread!=0)
# 与 InstrUncache 顶层那次的基线**逐个数字相同**（204/0/0/1），这不奇怪：
# InstrUncache 顶层下唯一的寄存器实体就是 entries_0 这一个 InstrMMIOEntry。
#
# 这一位是什么（论证与上面那段同源，不复述细节）：golden InstrMMIOEntry 锁存
# 48 位 MMIO 取指地址，之后只有两个读者 —— req_addr[2:1] 选半字、req_addr[47:3]
# 按 8 字节对齐发 Get ⇒ **bit 0 两侧同为死位**，1↔1 严格双射。
# 本钉点只消名差（golden 逐字段展平 req_addr_reg[0]；可读核 packed struct 展平
# req_reg\[addr][0]），不 dont_verify、不加黑盒、不约束 ref、不跳过任何比较点。
# 钉后配合 target-scoped vmucp（verif/fm_target_config/InstrMMIOEntry.tcl）
# FM 会**真去比这一位**，预期 passing 204 -> 205、unread -> 0。
#
# ★守卫为什么不用 catch★（本轮实测，不是引用传闻）
#   set_user_match 遇到不存在的名字**不抛 Tcl 异常**：它打一行
#   `Error: Unknown name: '...' (FM-036)` 然后正常返回。所以
#   `if {![catch {set_user_match ...}]}` 恒为真，是个空守卫。
#   证据在本 lane 同一轮的 evidence/6a9e4235497e/NewPipelineConnectPipe_29：
#   fm.log 行首锚定 `grep -cE "^ *Error:"` = 41 条全是 FM-036，条数恰等于 field map
#   里 width==1 的字段数；而同一份 log 的 match 统计写着
#   「41 Compare points matched by signature analysis」——
#   那 41 个点根本没被钉上，catch 一个都没拦住。
#   （上面 InstrUncache 那段写于本发现之前，仍是 catch 形状；本 lane 不改已出过证
#    的那段字节，只在这里用新做法，并把差别写明。）
#
# ★改用 find_cells 做 discover + 存在性断言★（safe interp 白名单里有它，
#   见 scripts/sidecar/fm_native_emit.tcl 的 alias 表）。判据是**可判别的**，
#   本 lane 用同一份设计跑过正反两组探针：
#     find_cells {r:/WORK/InstrMMIOEntry/req_addr_reg[0]}            -> 1
#     find_cells {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][0]}  -> 1
#     find_cells {r:/WORK/InstrMMIOEntry/req_addr_reg_NOSUCH[0]}     -> 0   ← 负测
#     find_cells {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][99]} -> 0   ← 负测
#   注意 find_cells 只在**设计自己的作用域**里列 cell（实例路径下枚举不到，
#   见 verif/ut/Predictor/fm_pins_pre.tcl 的 J 组探针），所以断言用设计作用域名
#   xs_InstrMMIOEntry_core/...，而 set_user_match 用实例路径 InstrMMIOEntry/u_core/...。
#   同时断言 report_unmatched_points 在 match 之前不可用（本 lane 探针实测它返回
#   标量 1 而不是列表），所以后置条件只能靠 find_cells，不能靠它。
#
# ★失败一律 error，不用 exit★：正式签核时本文件跑在 interp create -safe 里，
#   safe interp 隐藏 exit，写 exit 会静默什么都不做；error 才会穿出 interp eval
#   把 fm_shell 当场打死。
# ============================================================================
if {$top eq "InstrMMIOEntry"} {
  if {[info commands find_cells] eq ""} {
    error "INSTRMMIOENTRY_PIN: 只读查询动词 'find_cells' 不可用 —— 无法 discover，拒绝硬猜名字"
  }
  set _immio_ref_scope "r:/WORK/InstrMMIOEntry/req_addr_reg\[0\]"
  set _immio_imp_scope "i:/WORK/xs_InstrMMIOEntry_core/req_reg\\\[addr\]\[0\]"
  set _immio_ref_found [find_cells $_immio_ref_scope]
  set _immio_imp_found [find_cells $_immio_imp_scope]
  if {[llength $_immio_ref_found] != 1} {
    error "INSTRMMIOENTRY_PIN: ref 侧 $_immio_ref_scope 命中 [llength $_immio_ref_found] 个（应为 1）"
  }
  if {[llength $_immio_imp_found] != 1} {
    error "INSTRMMIOENTRY_PIN: impl 侧 $_immio_imp_scope 命中 [llength $_immio_imp_found] 个（应为 1）"
  }
  set_user_match "r:/WORK/InstrMMIOEntry/req_addr_reg\[0\]" \
                 "i:/WORK/InstrMMIOEntry/u_core/req_reg\\\[addr\]\[0\]"
  puts "INSTRMMIOENTRY_PINS: dead req_addr\[0\] 1 / 1 point pinned"
}
