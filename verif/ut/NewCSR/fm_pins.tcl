# NewCSR 父层装配 FM 匹配后钉点(bijection): 92 个对称 bug-for-bug 死寄存器。
#
# 这些寄存器在 golden(ref) 与可读核(impl) 两侧**都存在**、都被 firtool/写逻辑 faithfully
# 复刻, 但其输出高位/整字从不喂任何 rdata/output(cone-dead)。收窄 impl 会破坏
# bug-for-bug 复刻(红线), 故正解=显式一一双射 set_user_match, 配合 vmucp
# (verification_verify_matched_unread_compare_points=true) 让 FM **实际比较**这些点,
# 证明恒相等(同源同拍锁存同一 w_wdata 切片/同一 io_hpm_event 切片) → 从 unread 转 passing。
#
# 只 set_user_match, 不 dont_verify / 不约束 ref / 不强配不等价 / 不 relaxed。
# 每对的真等价证明见下方分族注释(逐位同 slice / 同 w_wen / 同 reset)。
#
# 名字/层次差异令 auto_match 配不上, 故逐位显式:
#   iprio : ref 命名 reg_Prio<Name>_reg[b]  vs  impl 命名 u_core/r<N>_reg[b]
#           (golden 具名字段 vs 可读核参数化 xs_iprio6 的 r0..r5)
#   hperf : ref/impl 叶名相同(event_op_2_reg[b] / event_op_2_reg_reg[b]),
#           仅差 impl 侧 u_core 层次前缀。
# 全部 catch 保护(点不存在则跳过, 不误报)。

set _npin 0
proc _pin {r i} {
  global _npin top
  if {![catch {set_user_match "r:/WORK/$top/$r" "i:/WORK/$top/u_core/$i"}]} { incr _npin }
}

# ============================================================================
# (A) iprio 未读优先级 lane 死寄存器 (72 = 9 reg × 8 bit)。
#
# 可读核 xs_iprio6 有 6 个 8 位裸寄存器 r0..r5, 每个从 w_wdata 的 WOFF<k> 切片锁存
# (if(reset) 0 else if(w_wen) …), 与 golden 具名字段 reg_Prio<Name> 的
# (if(reset) 0 else if(w_wen) reg_Prio<Name> <= w_wdata[hi:lo]) 逐字对应。
# w_wen/w_wdata 是父层 NewCSR 写路径喂给两侧同一实例的同一信号(父层 glue 已 FM 证等)。
# 下表每对 = 同一 w_wdata 切片、同一 w_wen、同一 reset → 恒相等。
#
#   实例      golden reg (未被任何 rdata 读)      impl r<N> (WOFF → w_wdata 切片)     真等价
#   miprio2   reg_Prio14   (w_wdata[55:48])        u_core/r4 (WOFF4=48 → [55:48])     ✓ 同切片
#   miprio2   reg_Prio15   (w_wdata[63:56])        u_core/r5 (WOFF5=56 → [63:56])     ✓ 同切片
#   siprio0   reg_PrioVSSI (w_wdata[23:16])        u_core/r1 (WOFF1=16 → [23:16])     ✓ 同切片
#   siprio0   reg_PrioMSI  (w_wdata[31:24])        u_core/r2 (WOFF2=24 → [31:24])     ✓ 同切片
#   siprio0   reg_PrioVSTI (w_wdata[55:48])        u_core/r4 (WOFF4=48 → [55:48])     ✓ 同切片
#   siprio0   reg_PrioMTI  (w_wdata[63:56])        u_core/r5 (WOFF5=56 → [63:56])     ✓ 同切片
#   siprio2   reg_PrioVSEI (w_wdata[23:16])        u_core/r0 (WOFF0=16 → [23:16])     ✓ 同切片
#   siprio2   reg_PrioMEI  (w_wdata[31:24])        u_core/r1 (WOFF1=24 → [31:24])     ✓ 同切片
#   siprio2   reg_PrioSGEI (w_wdata[39:32])        u_core/r2 (WOFF2=32 → [39:32])     ✓ 同切片
# ============================================================================
foreach {inst refreg implreg} {
  miprio2 reg_Prio14   r4
  miprio2 reg_Prio15   r5
  siprio0 reg_PrioVSSI r1
  siprio0 reg_PrioMSI  r2
  siprio0 reg_PrioVSTI r4
  siprio0 reg_PrioMTI  r5
  siprio2 reg_PrioVSEI r0
  siprio2 reg_PrioMEI  r1
  siprio2 reg_PrioSGEI r2
} {
  for {set b 0} {$b < 8} {incr b} {
    _pin "${inst}/${refreg}_reg\[$b\]" "${inst}/u_core/${implreg}_reg\[$b\]"
  }
}

# ============================================================================
# (B) HPerfMonitor event_op 死高位 (20 = 5 hpc × 2 reg × 2 bit)。
#
# golden/impl HPerfCounter_8 各有 5 位寄存器 event_op_2 (FM 名 event_op_2_reg) 与其打拍
# 副本 event_op_2_reg (FM 名 event_op_2_reg_reg), 两侧均 <= io_hpm_event[54:50] / <= event_op_2,
# 逐字相同(同 posedge clock, 无 reset, 同随机初值消除于 SYNTHESIS)。io_perf mux 只读
# [0]/[1]/[2] → 高位 [3][4] 两侧对称死。5 个 hpc 实例(perfEvents_hpc/_1.._4)结构相同。
# 叶名两侧相同, 仅差 u_core 前缀(_pin 已加), 逐位双射。
# ============================================================================
foreach hpc {perfEvents_hpc perfEvents_hpc_1 perfEvents_hpc_2 perfEvents_hpc_3 perfEvents_hpc_4} {
  foreach b {3 4} {
    _pin "hpmHc/${hpc}/event_op_2_reg\[$b\]"     "hpmHc/${hpc}/event_op_2_reg\[$b\]"
    _pin "hpmHc/${hpc}/event_op_2_reg_reg\[$b\]" "hpmHc/${hpc}/event_op_2_reg_reg\[$b\]"
  }
}

puts "NEWCSR_PINS: $_npin symmetric dead-reg bijections pinned (target 92)"
