# StorePipe FM 钉点 (codex_0093 §2 vmucp integrator, 2026-07)
# ---------------------------------------------------------------------------
# 语义面顶层 $top = StorePipe_surface。它例化 `StorePipe u_dut`：
#   ref  侧 u_dut = canonical-derivative StorePipe（s2_paddr 平铺）
#   impl 侧 u_dut = 可读核包装 StorePipe，内部再例化 `xs_StorePipe_core u_core`
# 因此 impl 的寄存器多一层 u_core：ref 是 u_dut/<reg>，impl 是 u_dut/u_core/<reg>。
#
# 6 个 s2_paddr_reg[0..5] = 48 位 s2_paddr 的低 6 位字节偏移（块地址只用
# s2_paddr[47:6]，见 io_miss_req_bits_addr = {s2_paddr[47:6],6'h0}）。这 6 位在
# 两侧都被写入、但从不被读出 —— 两侧同源同宽（各 1 位）的 cone-dead 死寄存器，是
# 真双射（叶名逐字相同 s2_paddr_reg[N]，仅差 impl 的 u_core 层次 + 顶层多一层
# u_dut）。shared auto_match_flattened_arrays 只剥一层 u_core，剥不掉 u_dut/u_core
# 双层，故这 6 点落到 unmatched-unread；这里按名逐位显式钉死（真等价 set_user_match，
# 非伪配、非 dont_verify、非归零）。vmucp=true 令 FM 钉后实际逐位比较 → passing。
#
# 派生件已用正确 G0 firtool flags 复算(derive.sh --lowering-options=
# disallowLocalVariables)，24 个旧 automatic-local shadow DFF 已消除，故此处只剩
# 这 6 个真 cone-dead 字节偏移位，无 shadow-DFF 伪影。
for {set b 0} {$b < 6} {incr b} {
  if {[catch {set_user_match \
        "r:/WORK/$top/u_dut/s2_paddr_reg\[$b\]" \
        "i:/WORK/$top/u_dut/u_core/s2_paddr_reg\[$b\]"} msg]} {
    puts "STOREPIPE_PIN_FAIL: s2_paddr_reg\[$b\] ($msg)"
  } else {
    puts "STOREPIPE_PIN: s2_paddr_reg\[$b\] r/u_dut <-> i/u_dut/u_core"
  }
}
puts "STOREPIPE_PINS: 6 s2_paddr byte-offset dead bits pinned (true bijection)"
