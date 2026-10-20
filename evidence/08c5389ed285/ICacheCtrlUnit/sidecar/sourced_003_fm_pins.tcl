# ICacheCtrlUnit FM 钉点 (FM 审计 2026-07)
# --------------------------------------------------------------------------
# out_back_q = Queue1_RegMapperInput_5 (RegMapper 输出背压队列; G0 里叫 _3,
# G1 只把 TileLink source 从 3 位加宽到 5 位, ram 82->84 位, data 段位置不变)。RegMapper 的通用
# data 字段宽 64 位, 但 ICacheCtrlUnit 只消费 data[47:0](ECC 控制字/ecciaddr paddr)
# 加若干低控制位; data[63:48] 这 16 位存入队列却从不被父级读出 —— 在 golden 与手写核
# 里都是死位 (bug-for-bug 一致)。
#   golden : 队列存储打包成 ram_reg, data[48+k] 落在绝对位 ram_reg[53+k] (k=0..15)
#   手写核 : 用可读 struct slot (reg_req_t), FM 展平名 slot_reg\[data][48+k]
# 词干不同 (ram_reg vs slot_reg[data]) 令 auto_match_flattened_arrays 无法配对
# → 16 (ref) + 16 (impl) unmatched-unread。二者是严格 16↔16 双射: 同为 queue entry
# 的 data 位 48+k, 同源 io_enq_bits_data[48+k] 锁存。按名逐位 set_user_match。
# 仅消名差, 不约束 ref, 不 dont_verify, 不扩黑盒 (符合 reviewer ICache 裁定第 1 条)。
# 对 Queue1_RegMapperInput_5 变体 (out_back_q 即为 top、data 位是输出端口不死),
# 下列路径不存在 → set_user_match 抛错被 catch 吞掉, 无副作用。
# --------------------------------------------------------------------------
# ★2026-09-20 改成 fail-closed（agent/provefleet2）★
#   原来是 `if {![catch {set_user_match ...}]} { incr _n }`。`set_user_match`
#   找不到名字时**不抛 Tcl 异常**（返回 0，往 fm.log 写 `Error: Unknown name: (FM-036)`），
#   所以 `_n` 恒为 16 —— 上面注释里"下列路径不存在 → set_user_match 抛错被 catch 吞掉"
#   这句话本身就是错的：它不抛错，它返回 0。那行 "$_n / 16" 从来没有被校验过。
#   改法照 verif/ut/EnqEntry/fm_pins_pre.tcl：用**返回值**计数，最后一次
#   set_user_match 之后用字面整数守卫，中止一律 `error`（★不许 exit★：正式签核时
#   钉点跑在 `interp create -safe` 里，safe interp 隐藏 exit）。
#   同时把 `$top` 门控显式写出来（本 UT 的 FM_VARIANTS 只有 ICacheCtrlUnit 一个，
#   写出来是为了让"只对这个 top 钉"成为代码而不是注释）。
#   发射出去的 set_user_match 调用序列一字未改（scripts/pin_call_equiv.py 守这条）。
if {$top eq "ICacheCtrlUnit"} {
  set _n 0
  set _miss 0
  for {set k 0} {$k < 16} {incr k} {
    set br [expr {53 + $k}]
    set bi [expr {48 + $k}]
    if {[set_user_match "r:/WORK/$top/out_back_q/ram_reg\[$br\]" \
                        "i:/WORK/$top/out_back_q/slot_reg\\\[data\]\[$bi\]"]} {
      incr _n
    } else {
      incr _miss
      puts "ICACHECTRLUNIT_PIN_FAIL: ram_reg\[$br\] <-> slot_reg\\\[data\]\[$bi\]"
    }
  }
  puts "ICACHECTRLUNIT_PINS: out_back_q dead data\[63:48\] $_n / 16 points pinned"
  if {$_miss != 0} { error "ICACHECTRLUNIT_PIN_REFUSED=$_miss" }
  if {$_n != 16} { error "ICACHECTRLUNIT_PIN_COUNT=$_n expected 16" }
}
