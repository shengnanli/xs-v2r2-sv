# IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v FM 钉点 (FM 审计 2026-07)
# --------------------------------------------------------------------------
# validCntDeqVec 寄存器 bit[5] 对称死位 (双射 2↔2)。
#
# io_validCntDeqVec_{0,1} = 「在队且本端口可接 (deqCanAccept)」的 uop popcount
# 减去本拍出队消耗。本 IQ 条目总数 NUM_ENTRIES=24 (< 32 = 2^5), 减法结果域
# [0..24], 故每个 validCntDeqVec_N 寄存器的 bit[5] (MSB) 在两侧都恒不置位、
# 也从不被读出 (输出只取 [4:0]) —— golden 与手写核 bug-for-bug 一致的对称内部
# 死位。本 IQ 2 个发射端口 (NUM_DEQ=2) => 2 对, 与 sibling
# IssueQueueAluMulBkuBrhJmp 同型 (该 IQ 2 deq 口=2 对)。
#
# 命名:
#   golden : io_validCntDeqVec_{0,1}_REG_reg[5]   (reg [5:0]，输出 [4:0])
#   手写核 : u_core/validCntDeqVec{0,1}_reg_reg[5] (reg [5:0]，输出 [4:0])
# 词干不同 (io_validCntDeqVec_N_REG vs validCntDeqVecN_reg) 令
# auto_match_flattened_arrays 无法自动配对 => 2(ref)+2(impl) unmatched-unread。
# 二者严格 2↔2 双射: 同为 validCntDeqVec_N 的 bit5, 同源 popcount-减法。
# 按语义逐位 set_user_match。仅消名差, 不约束 ref, 不 dont_verify, 不扩黑盒。
# 配合 declarations 第5列 verify_matched_unread_compare_points=true, FM 实际开启
# 比较这些 mapped 死位并 SUCCEEDED = 对称内部死状态的双射匹配证明 (非 waiver)。
#
# 说明: 156 个 entries srcType[3:1]/enqDelay srcLoadDependency LSB 等对称
# matched-unread 死位位于共享 golden 子模块 entries/* 内 (ref/impl 两侧例化同一
# golden RTL EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv), 名字两侧同 =>
# auto_match 自动配对, 无需 pin; IQ 顶层仅剩 validCntDeqVec bit[5] 名差须 pin。
# --------------------------------------------------------------------------
if {$top eq "IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v"} {
  set _m 0
  foreach k {0 1} {
    set rpath "r:/WORK/$top/io_validCntDeqVec_${k}_REG_reg\[5\]"
    set ipath "i:/WORK/$top/u_core/validCntDeqVec${k}_reg_reg\[5\]"
    if {![catch {set_user_match $rpath $ipath} msg]} {
      incr _m
    } else {
      puts "IQABJIVVI_PIN_MISS: $rpath <-> $ipath : $msg"
    }
  }
  puts "IQABJIVVI_PINS: validCntDeqVec dead bit5 $_m / 2 points pinned"
}
