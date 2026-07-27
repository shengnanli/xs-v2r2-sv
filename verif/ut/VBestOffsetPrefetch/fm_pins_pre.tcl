# VBestOffsetPrefetch matched-unread bijection pins (codex_0073 phase1 收口).
#
# 消 PrefetchReqBuffer 黑盒后, VBestOffsetPrefetch 唯一残余 384 unread =
# DelayQueue_1 的 16 条目 queue_<N>_addrNoOffset 各顶 24 位 [43:20]:
#   golden DelayQueue 存 44 位 addrNoOffset(io_out_bits = {addrNoOffset,6'h0} 后
#   写 RRT SRAM), 但下游只消费低 20 位([19:0])——顶 24 位在 ref/impl 两侧都写不读,
#   为忠实复刻的对称死位(impl 也存全宽 44 位 queue_addr, 不过宽)。
#
# ref  叶名: r:/WORK/VBestOffsetPrefetch/delayQueue/queue_<N>_addrNoOffset_reg[b]
# impl 叶名: i:/WORK/VBestOffsetPrefetch/u_core/delayQueue/queue_addr_reg[<N>][b]
#   (SV 2D 数组 reg [43:0] queue_addr [0:15])。
# firtool 展平命名 vs SV 数组命名, auto_match_flattened_arrays 不覆盖 unread 点,
# 故这里显式 set_user_match 建立双射; verify_matched_unread_compare_points=true
# 让 FM **实际逐位比较**这 384 点(证双射且相等)→从 Not-Compared 提升为 Passing。
# 这是加强证明(证得更多), 非 waiver。
#
# ★必须是 FM_PIN_PRE_TCL(首次 match 之前钉)★: 若放 match 后(fm_pins.tcl), 首个
# match 表会先打印 384(384) unread 行, fm_verdict._unmatch_pair 取全文最后一次
# 匹配→被这条 stale 首表行骗成 PARTIAL(即便最终表 0 unread/384 passing)。放 pre
# 则首表即 0 unread, 全文无残影 unread 行(见 fm-tl2-l2top-signoff 教训)。

set top VBestOffsetPrefetch
set n 0
for {set e 0} {$e < 16} {incr e} {
  for {set b 20} {$b < 44} {incr b} {
    set rpath "r:/WORK/$top/delayQueue/queue_${e}_addrNoOffset_reg\[$b\]"
    set ipath "i:/WORK/$top/u_core/delayQueue/queue_addr_reg\[$e\]\[$b\]"
    if {[catch {set_user_match $rpath $ipath} msg]} {
      puts "VBOP_PIN_FAIL: $rpath <-> $ipath ($msg)"
    } else {
      incr n
    }
  }
}
puts "VBOP_DELAYQUEUE_PINS: $n points pinned"
