# EntriesAluCsrFenceDiv FM 钉点 (FM 审计 2026-07)
# --------------------------------------------------------------------------
# enqDelayIn1 srcLoadDependency 寄存器的 bit[0] 对称死位 (双射 12↔12)。
#
# golden 与手写核都在 Entries 顶层用 RegEnable(enq.payload.srcLoadDependency,
# enq.valid) 锁存入队原始 load 依赖 (喂 EnqEntry 的 enqDelayIn1)。loadDependency
# 是 LoadDependencyWidth=2 的移位寄存器: 唤醒时左移 (`{dep[0],1'b0}`), loadCancel
# 只看 dep[p][1]。因此每个 srcLoadDependency[s][p] 的 **bit[0] (LSB) 在两侧都从不
# 被读出** —— golden(r_*)与手写核(enqd1_src_ld)是 bug-for-bug 一致的对称内部死位。
#
# 命名:
#   golden : 顶层扁平寄存器 r_{...}  (r_S_P = enq0; r_1_S_P = enq1)
#            r_0_0=(enq0,src0,pipe0) r_0_1=(enq0,src0,pipe1) r_0_2=(enq0,src0,pipe2)
#            r_1_0=(enq0,src1,pipe0) r_1_1=(enq0,src1,pipe1) r_1_2=(enq0,src1,pipe2)
#            r_1_0_0=(enq1,src0,pipe0) ... r_1_1_2=(enq1,src1,pipe2)
#   手写核 : u_core/enqd1_src_ld_reg[enq][src][pipe][bit]  (bit=0 即死位)
#
# 词干不同 (r_* vs enqd1_src_ld) 令 auto_match_flattened_arrays 无法自动配对
# → 12(ref) + 12(impl) unmatched-unread。二者严格 12↔12 双射: 同为 enqDelayIn1
# srcLoadDependency[s][p] 的 bit0, 同源 io_enq_Q_bits_payload_srcLoadDependency_S_P
# 锁存。按语义逐位 set_user_match。仅消名差, 不约束 ref, 不 dont_verify, 不扩黑盒。
# 配合 declarations 第5列 verify_matched_unread_compare_points=true, FM 实际开启
# 比较这些 mapped 死位并 SUCCEEDED = 对称内部死状态的双射匹配证明 (非 waiver)。
# --------------------------------------------------------------------------

# 本 fm_pins.tcl 由 EntriesAluCsrFenceDiv(Makefile)与 IssueQueueAluCsrFenceDiv
# (Makefile.iq)两个 target 共享(同目录 fm_pins.tcl 自动作 FM_PIN_TCL)。按 $top 分支:
#   - Entries 顶层: r_* 与 enqd1_src_ld 都在 Entries 模块顶层 → 词干不同须逐位 pin。
#   - IQ 顶层: 上述 enqDelayIn1 死位在 IQ 里位于共享 golden 子模块 entries/r_* 内,
#     ref/impl 同名(entries 两侧例化同一 golden RTL)→ auto_match 自动配对, 无需 pin;
#     IQ 仅剩 validCntDeqVec 寄存器 bit[5] 名差(io_validCntDeqVec_0_REG vs
#     validCntDeqVec0_reg)须 pin(见下)。

if {$top eq "EntriesAluCsrFenceDiv"} {
  # golden 顶层名 -> 手写核 enqd1_src_ld[enq][src][pipe][0]
  set _pairs {
    r_0_0     {0 0 0}
    r_0_1     {0 0 1}
    r_0_2     {0 0 2}
    r_1_0     {0 1 0}
    r_1_1     {0 1 1}
    r_1_2     {0 1 2}
    r_1_0_0   {1 0 0}
    r_1_0_1   {1 0 1}
    r_1_0_2   {1 0 2}
    r_1_1_0   {1 1 0}
    r_1_1_1   {1 1 1}
    r_1_1_2   {1 1 2}
  }

  set _n 0
  foreach {gname idx} $_pairs {
    set q [lindex $idx 0]
    set s [lindex $idx 1]
    set p [lindex $idx 2]
    set rpath "r:/WORK/$top/${gname}_reg\[0\]"
    set ipath "i:/WORK/$top/u_core/enqd1_src_ld_reg\[$q\]\[$s\]\[$p\]\[0\]"
    if {![catch {set_user_match $rpath $ipath} msg]} {
      incr _n
    } else {
      puts "ENTRIESACFD_PIN_MISS: $rpath <-> $ipath : $msg"
    }
  }
  puts "ENTRIESACFD_PINS: enqDelayIn1 srcLoadDependency dead bit0 $_n / 12 points pinned"
}

# --------------------------------------------------------------------------
# IssueQueueAluCsrFenceDiv target: validCntDeqVec 寄存器 bit[5] 对称死位 (双射 1↔1)。
# --------------------------------------------------------------------------
# io_validCntDeqVec_0 = 「在队且端口0可接(CSR类)」的 uop popcount 减去本拍出队消耗。
# 最大在队条目 24, 减法结果域 [0..24] < 32, 故 bit[5] (MSB) 在两侧都恒不置位、
# 也从不被读出 (输出只取 [4:0]) —— golden 与手写核 bug-for-bug 一致的对称内部死位。
# 与 sibling IssueQueueAluMulBkuBrhJmp 同型 (该 IQ 2 deq 口=2对; 本 IQ 1 deq 口=1对)。
#   golden : io_validCntDeqVec_0_REG_reg[5]   (reg [5:0]，输出 [4:0])
#   手写核 : u_core/validCntDeqVec0_reg_reg[5] (reg [5:0]，输出 [4:0])
# 词干不同 (io_validCntDeqVec_0_REG vs validCntDeqVec0_reg) 令 auto_match 无法配对
# → 1(ref)+1(impl) unmatched-unread。严格 1↔1 双射: 同为 validCntDeqVec_0 的 bit5,
# 同源 popcount-减法。set_user_match 消名差。仅消名差, 不约束 ref, 不 dont_verify,
# 不扩黑盒。配合 verify_matched_unread_compare_points=true, FM 实际开启比较该 mapped
# 死位并 SUCCEEDED = 对称内部死状态的双射匹配证明 (非 waiver)。
if {$top eq "IssueQueueAluCsrFenceDiv"} {
  set _m 0
  set rpath "r:/WORK/$top/io_validCntDeqVec_0_REG_reg\[5\]"
  set ipath "i:/WORK/$top/u_core/validCntDeqVec0_reg_reg\[5\]"
  if {![catch {set_user_match $rpath $ipath} msg]} {
    incr _m
  } else {
    puts "IQACFD_PIN_MISS: $rpath <-> $ipath : $msg"
  }
  puts "IQACFD_PINS: validCntDeqVec dead bit5 $_m / 1 points pinned"
}
