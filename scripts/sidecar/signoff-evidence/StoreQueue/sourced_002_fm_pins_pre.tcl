# StoreQueue FM 钉点（FM 审计 2026-07；本轮修正 impl 寄存器名 uop_r_reg→uop_reg 并补全）
# 1) 5 个共享 golden 子模块两侧同定义，只差实例名 → 层次 compare rule。
# 2) per-entry 状态位/uop 元数据：golden 逐 entry 展平（<field>_<n> / uop_<n>_<field>）
#    ↔ impl struct 数组（ent_reg[n][field] / uop_reg[n][field]），显式钉（56 entry）。
# 3) forward 三路流水寄存器：golden 展平后缀（"", _1, _2 / r, r_1..r_5）↔ impl
#    generate 块 g_fwd[k] 内的 *_q 寄存器。
setup

# FM 的寄存器初值推断（Auto）会把一侧部分寄存器约束成常量（两侧不对称 → 锥失配），关掉。
if {[catch {set_app_var verification_assume_reg_init none} msg]} { puts "PINS: assume_reg_init failed: $msg" }
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} { puts "PINS: undriven failed: $msg" }
foreach {f t} {
  {^u_core/u_data/}    {dataModule/}
  {^u_core/u_paddr/}   {paddrModule/}
  {^u_core/u_vaddr/}   {vaddrModule/}
  {^u_core/u_databuf/} {dataBuffer/}
  {^u_core/u_excbuf/}  {exceptionBuffer/}
  {^u_core/}           {}
} {
  foreach ty {cell net port pin} {
    catch {set_compare_rule "i:/WORK/$top" -type $ty -from $f -to $t}
  }
}

set _n 0
proc pin {r i} {
  global _n
  if {![catch {set_user_match "r:/WORK/StoreQueue/$r" "i:/WORK/StoreQueue/u_core/$i"}]} { incr _n }
}

# ---- per-entry 状态位（sq_entry_t ↔ golden 散列 Vec(Bool)）----
foreach f {allocated completed addrvalid datavalid committed unaligned cross16Byte
           pending nc mmio memBackTypeMM prefetch isVec vecLastFlow vecMbCommit
           hasException waitStoreS2} {
  for {set n 0} {$n < 56} {incr n} {
    pin "${f}_${n}_reg" "ent_reg\[$n\]\\\[$f\]"
  }
}

# ---- uop 多位字段 ----
foreach {gf if w} {
  robIdx_value          robIdx_value   8
  uopIdx                uopIdx         7
  fuOpType              fuOpType       9
  fuType                fuType         35
  sqIdx_value           sqIdx_value    6
  trigger               trigger        4
  debugInfo_enqRsTime   dbg_enqRsTime  64
  debugInfo_selectTime  dbg_selectTime 64
  debugInfo_issueTime   dbg_issueTime  64
} {
  for {set n 0} {$n < 56} {incr n} {
    for {set b 0} {$b < $w} {incr b} {
      pin "uop_${n}_${gf}_reg\[$b\]" "uop_reg\[$n\]\\\[$if\]\[$b\]"
    }
  }
}
# ---- uop 1 位字段 ----
foreach {gf if} {robIdx_flag robIdx_flag sqIdx_flag sqIdx_flag lastUop lastUop flushPipe flushPipe} {
  for {set n 0} {$n < 56} {incr n} {
    pin "uop_${n}_${gf}_reg" "uop_reg\[$n\]\\\[$if\]"
  }
}
# ---- uop exceptionVec（golden 逐位 reg ↔ impl 24 位字段）----
for {set n 0} {$n < 56} {incr n} {
  for {set k 0} {$k < 24} {incr k} {
    pin "uop_${n}_exceptionVec_${k}_reg" "uop_reg\[$n\]\\\[exceptionVec\]\[$k\]"
  }
}
# ---- cboZeroUop.exceptionVec 锁存 ----
for {set k 0} {$k < 24} {incr k} {
  pin "cboZeroUop_exceptionVec_${k}_reg" "cbz_excVec_reg\[$k\]"
}

# ---- forward 三路 s2 流水寄存器（g_fwd[k]）----
foreach {k s} {0 {} 1 {_1} 2 {_2}} {
  for {set b 0} {$b < 56} {incr b} {
    pin "dataInvalidMask1Reg_REG${s}_reg\[$b\]" "g_fwd\[$k\].di1_q_reg\[$b\]"
    pin "dataInvalidMask2Reg_REG${s}_reg\[$b\]" "g_fwd\[$k\].di2_q_reg\[$b\]"
    pin "addrInvalidMask1Reg_REG${s}_reg\[$b\]" "g_fwd\[$k\].ai1_q_reg\[$b\]"
    pin "addrInvalidMask2Reg_REG${s}_reg\[$b\]" "g_fwd\[$k\].ai2_q_reg\[$b\]"
    pin "vpmaskNotEqual_REG${s}_reg\[$b\]"      "g_fwd\[$k\].needFwd_q_reg\[$b\]"
    pin "vpmaskNotEqual_next_r${s}_reg\[$b\]"   "g_fwd\[$k\].addrRealValid_q_reg\[$b\]"
  }
}
# vpmaskNotEqual_r 对（paddr/vaddr forwardMmask 打拍）：port0 r/r_1, port1 r_2/r_3, port2 r_4/r_5
foreach {k pa va} {0 vpmaskNotEqual_r vpmaskNotEqual_r_1
                   1 vpmaskNotEqual_r_2 vpmaskNotEqual_r_3
                   2 vpmaskNotEqual_r_4 vpmaskNotEqual_r_5} {
  for {set b 0} {$b < 56} {incr b} {
    pin "${pa}_reg\[$b\]" "g_fwd\[$k\].paFwd_q_reg\[$b\]"
    pin "${va}_reg\[$b\]" "g_fwd\[$k\].vaFwd_q_reg\[$b\]"
  }
}
# forward 输出寄存器（loadWaitStrict / hasInvalidAddr / sqIdx 打拍）
foreach {k s} {0 0 1 1 2 2} {
  pin "io_forward_${s}_addrInvalid_r_reg"   "g_fwd\[$k\].loadWaitStrict_q_reg"
  pin "io_forward_${s}_addrInvalid_REG_reg" "g_fwd\[$k\].hasInvalidAddr_q_reg"
  # dataInvalidSqIdx_r 与 addrInvalidSqIdx_r_1 在 golden 是两个独立寄存器（值恒同）：
  #   data 路配 fwdSqIdxData_q，addr_1 路配 fwdSqIdx_q（各一份，消 merge_dup=false 下的自由变量）。
  pin "io_forward_${s}_dataInvalidSqIdx_r_flag_reg" "g_fwd\[$k\].fwdSqIdxData_q_reg\[6\]"
  pin "io_forward_${s}_addrInvalidSqIdx_r_1_flag_reg" "g_fwd\[$k\].fwdSqIdx_q_reg\[6\]"
  pin "io_forward_${s}_addrInvalidSqIdx_r_flag_reg" "g_fwd\[$k\].fwdSqIdxM1_q_reg\[6\]"
  for {set b 0} {$b < 6} {incr b} {
    pin "io_forward_${s}_dataInvalidSqIdx_r_value_reg\[$b\]" "g_fwd\[$k\].fwdSqIdxData_q_reg\[$b\]"
    pin "io_forward_${s}_addrInvalidSqIdx_r_1_value_reg\[$b\]" "g_fwd\[$k\].fwdSqIdx_q_reg\[$b\]"
    pin "io_forward_${s}_addrInvalidSqIdx_r_value_reg\[$b\]" "g_fwd\[$k\].fwdSqIdxM1_q_reg\[$b\]"
  }
}
# loadWaitStrict 第二份副本（golden r_5_0/r_9_0/r_13_0 = RegNext(loadWaitStrict)，data 路对偶）：
#   port0→r_5_0, port1→r_9_0, port2→r_13_0  ↔  g_fwd[k].loadWaitStrictData_q
foreach {k r} {0 r_5_0 1 r_9_0 2 r_13_0} {
  pin "${r}_reg" "g_fwd\[$k\].loadWaitStrictData_q_reg"
}

# ---- 向量异常标志 ----
pin "vecExceptionFlag_bits_robIdx_flag_reg" "vecExceptionFlag_robIdx_flag_reg"
for {set b 0} {$b < 8} {incr b} {
  pin "vecExceptionFlag_bits_robIdx_value_reg\[$b\]" "vecExceptionFlag_robIdx_value_reg\[$b\]"
}

# ---- 杂项小寄存器 ----
pin "lastEnqCancel_reg\[0\]" "lastEnqCancel_q_reg\[0\]"
pin "lastEnqCancel_reg\[1\]" "lastEnqCancel_q_reg\[1\]"
pin "lastlastCycleRedirect_reg" "lastlastCycleRedirect_q_reg"
for {set b 0} {$b < 8} {incr b} {
  pin "redirectCancelCount_reg\[$b\]" "redirectCancelCount_q_reg\[$b\]"
}
# uncacheUop 的 exceptionVec(19)（hardwareError）
pin "uncacheUop_exceptionVec_19_reg" "uncUop_excHwErr_reg"

# ---- pendingPtr 每提交口副本（golden next_r / next_r_1..7）----
foreach {k s} {0 {} 1 _1 2 _2 3 _3 4 _4 5 _5 6 _6 7 _7} {
  pin "next_r${s}_flag_reg" "pendingPtrDup_q_reg\[$k\]\[8\]"
  for {set b 0} {$b < 8} {incr b} {
    pin "next_r${s}_value_reg\[$b\]" "pendingPtrDup_q_reg\[$k\]\[$b\]"
  }
}
# ---- rdataPtrNext 副本（mmio/nc × robIdx/memBackTypeMM）----
foreach {k g} {0 mmioReq_bits_robIdx 1 mmioReq_bits_memBackTypeMM 2 ncReq_bits_robIdx 3 ncReq_bits_memBackTypeMM} {
  pin "${g}_next_r_flag_reg" "rdNextPtrDup_q_reg\[$k\]\\\[flag\]"
  for {set b 0} {$b < 6} {incr b} {
    pin "${g}_next_r_value_reg\[$b\]" "rdNextPtrDup_q_reg\[$k\]\\\[value\]\[$b\]"
  }
}

# ---- validVStoreFlow_REG 每 enq 口副本（golden RegNext(redirect) 复制 6 份）----
#   golden: validVStoreFlow_REG / _1 / _2 / _3 / _4 / _5  ↔  impl redirValid_q[0..5]
foreach {k s} {0 {} 1 _1 2 _2 3 _3 4 _4 5 _5} {
  pin "validVStoreFlow_REG${s}_reg" "redirValid_q_reg\[$k\]"
}

puts "SQ_PINS: $_n points pinned"
