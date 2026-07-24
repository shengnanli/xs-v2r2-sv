# LoadQueueReplay FM 钉点（FM 审计 2026-07）
# 子模块（vaddrModule/freeList/ageOldest_age*）两侧同黑盒（Makefile 已清 FM_REF_DEPS）。
# 核内 72-entry 元数据：golden 逐 entry 展平 ↔ impl struct/packed 数组，显式钉。
setup

# FM 的寄存器初值推断（Auto）会把一侧部分寄存器约束成常量（两侧不对称 → 锥失配），关掉。
if {[catch {set_app_var verification_assume_reg_init none} msg]} { puts "PINS: assume_reg_init failed: $msg" }
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} { puts "PINS: undriven failed: $msg" }

# ---- ent 状态位（1 位 × 72）----
foreach {gf if} {
  allocated allocated
  scheduled scheduled
  blocking  blocking
  strict    strict
} {
  for {set n 0} {$n < 72} {incr n} {
    catch {set_user_match "r:/WORK/$top/${gf}_${n}_reg" \
                          "i:/WORK/$top/u_core/ent_reg\[$n\]\\\[$if\]"}
  }
}
# ---- dataInLastBeatReg（1 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  catch {set_user_match "r:/WORK/$top/dataInLastBeatReg_${n}_reg" \
                        "i:/WORK/$top/u_core/dataInLastBeat_reg\[$n\]"}
}
# ---- s0_loadFreeSelMask_next_r（72 位 packed）----
for {set b 0} {$b < 72} {incr b} {
  catch {set_user_match "r:/WORK/$top/s0_loadFreeSelMask_next_r_reg\[$b\]" \
                        "i:/WORK/$top/u_core/loadFreeSelMask_q_reg\[$b\]"}
}
# ---- uop debugInfo（64 位 × 72 × 3 字段）----
foreach {gf if} {
  debugInfo_enqRsTime  dbg_enqRsTime
  debugInfo_selectTime dbg_selectTime
  debugInfo_issueTime  dbg_issueTime
} {
  for {set n 0} {$n < 72} {incr n} {
    for {set b 0} {$b < 64} {incr b} {
      catch {set_user_match "r:/WORK/$top/uop_${n}_${gf}_reg\[$b\]" \
                            "i:/WORK/$top/u_core/uop_reg\[$n\]\\\[$if\]\[$b\]"}
    }
  }
}
# ---- s1_oldestSel 流水寄存器（3 路：valid + 7 位下标）----
for {set i 0} {$i < 3} {incr i} {
  catch {set_user_match "r:/WORK/$top/s1_oldestSel_${i}_valid_r_reg" \
                        "i:/WORK/$top/u_core/s1_oldestSel_valid_q_reg\[$i\]"}
  for {set b 0} {$b < 7} {incr b} {
    catch {set_user_match "r:/WORK/$top/s1_oldestSel_${i}_bits_r_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s1_oldestSel_bits_q_reg\[$i\]\[$b\]"}
  }
}
# ---- missMSHRId / tlbHintId（golden 5 位 [4:0]=零扩展；impl 现同为 5 位数组 [4:0]）----
# golden 与 impl 均把 4 位端口零扩展到 5 位存储，bit[4] 恒 0 且在 `==` 比较中被读（compare
# point，双方 0==0 passing）。逐位 1:1 双射 [4:0] 全部钉点（含 bit[4]），消 compare_ref 失配。
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 5} {incr b} {
    catch {set_user_match "r:/WORK/$top/missMSHRId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/missMSHRId_reg\[$n\]\[$b\]"}
    catch {set_user_match "r:/WORK/$top/tlbHintId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/tlbHintId_reg\[$n\]\[$b\]"}
  }
}

# ---- redirect 流水寄存器：golden 3 份副本(s0_can_go_REG/_1/_2 + s1_cancel_REG/_1/_2)
#      = RegNext(io_redirect_*)，impl 单份 redirect_*_q。FM 合并重复寄存器把 3 份塌成 1，
#      须先把各副本都钉到 impl 单寄存器（多对一，合并后一致）。robIdx 是 packed{flag,value[7:0]}
#      → 位[8]=flag, 位[7:0]=value。----
foreach pfx {s0_can_go_REG s0_can_go_REG_1 s0_can_go_REG_2 s1_cancel_REG s1_cancel_REG_1 s1_cancel_REG_2} {
  catch {set_user_match "r:/WORK/$top/${pfx}_valid_reg"          "i:/WORK/$top/u_core/redirect_valid_q_reg"}
  catch {set_user_match "r:/WORK/$top/${pfx}_bits_robIdx_flag_reg" "i:/WORK/$top/u_core/redirect_robIdx_q_reg\[8\]"}
  catch {set_user_match "r:/WORK/$top/${pfx}_bits_level_reg"     "i:/WORK/$top/u_core/redirect_level_q_reg"}
  for {set b 0} {$b < 8} {incr b} {
    catch {set_user_match "r:/WORK/$top/${pfx}_bits_robIdx_value_reg\[$b\]" \
                          "i:/WORK/$top/u_core/redirect_robIdx_q_reg\[$b\]"}
  }
}

# ---- s2 流水 payload 的对称 cone-dead 寄存器双射钉点（3 路）----
#  golden s2_replayCauses(port0 无后缀)/_1/_2 各 11 位，只 s2_replayCauses_N[4]被读(forward_tlDchannel)
#  → 其余 10 位两侧都存都不读=对称 matched-unread；impl s2_cause_q_reg[N][b] 同型。逐位钉双射，
#  让 FM 把两侧未读位配成 matched-unread（verify_matched_unread=true 下实开比较 0..10 全 passing）。
#  s2_replayMSHRId(port0 无后缀)/_1/_2 各 5 位，输出取[3:0]，bit[4]两侧都存不读=对称死→同法钉。
for {set i 0} {$i < 3} {incr i} {
  set gsuf [expr {$i == 0 ? "" : "_$i"}]
  for {set b 0} {$b < 11} {incr b} {
    catch {set_user_match "r:/WORK/$top/s2_replayCauses${gsuf}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_cause_q_reg\[$i\]\[$b\]"}
  }
  for {set b 0} {$b < 5} {incr b} {
    catch {set_user_match "r:/WORK/$top/s2_replayMSHRId${gsuf}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_mshr_q_reg\[$i\]\[$b\]"}
  }
}

puts "LQR_PINS: applied"
