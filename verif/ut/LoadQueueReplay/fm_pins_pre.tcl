# LoadQueueReplay FM 钉点（G1 / 本轮）
#
# golden 把 72 条 entry 的每个字段展平成独立寄存器名（allocated_17、uop_5_pc…），
# 可读核用 struct 数组（ent_reg[17][allocated]、uop_reg[5][p][pc]）。FM 的自动
# 配对按名字做，这两套名字对不上，于是要逐个钉。钉点**不放宽任何判据**：
# set_user_match 只是告诉 FM「这两个点是同一个点」，比还是照比。
#
# 子模块 vaddrModule / freeList / ageOldest_age* 两侧同为未解析黑盒
# （Makefile 的 FM_REF_DEPS_LoadQueueReplay 为空，UT 侧的定义走 GOLDEN_SRCS，
#  不进 FM_IMPL_SRCS），配成 matched blackbox pair。
setup

# FM 的寄存器初值推断（Auto）会把一侧的部分寄存器约束成常量，两侧不对称就成锥失配。关掉。
if {[catch {set_app_var verification_assume_reg_init none} msg]} { puts "PINS: assume_reg_init failed: $msg" }
if {[catch {set_app_var verification_set_undriven_signals BINARY} msg]} { puts "PINS: undriven failed: $msg" }

# ---- entry 控制位（1 位 × 72 × 4 个字段）----
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

# ---- dataInLastBeat（1 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  catch {set_user_match "r:/WORK/$top/dataInLastBeatReg_${n}_reg" \
                        "i:/WORK/$top/u_core/dataInLastBeat_reg\[$n\]"}
}

# ---- s0_loadFreeSelMask_next_r（72 位）----
for {set b 0} {$b < 72} {incr b} {
  catch {set_user_match "r:/WORK/$top/s0_loadFreeSelMask_next_r_reg\[$b\]" \
                        "i:/WORK/$top/u_core/loadFreeSelMask_q_reg\[$b\]"}
}

# ---- missMSHRId / tlbHintId（两侧都是 5 位：4 位端口零扩展）----
#  bit[4] 恒 0 但 golden 在 `==` 比较里**读**它，是个 compare point（0==0 passing）。
#  逐位 1:1 钉满 [4:0]，否则 golden 的 bit[4] 成 unmatched compare_ref。
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 5} {incr b} {
    catch {set_user_match "r:/WORK/$top/missMSHRId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/missMSHRId_reg\[$n\]\[$b\]"}
    catch {set_user_match "r:/WORK/$top/tlbHintId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/tlbHintId_reg\[$n\]\[$b\]"}
  }
}

# ---- cause（11 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 11} {incr b} {
    catch {set_user_match "r:/WORK/$top/cause_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/cause_reg\[$n\]\[$b\]"}
  }
}

# ---- debug_vaddr（50 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 50} {incr b} {
    catch {set_user_match "r:/WORK/$top/debug_vaddr_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/debug_vaddr_reg\[$n\]\[$b\]"}
  }
}

# ---- blockSqIdx（packed {flag, value[5:0]} × 72）----
for {set n 0} {$n < 72} {incr n} {
  catch {set_user_match "r:/WORK/$top/blockSqIdx_${n}_flag_reg" \
                        "i:/WORK/$top/u_core/blockSqIdx_reg\[$n\]\[6\]"}
  for {set b 0} {$b < 6} {incr b} {
    catch {set_user_match "r:/WORK/$top/blockSqIdx_${n}_value_reg\[$b\]" \
                          "i:/WORK/$top/u_core/blockSqIdx_reg\[$n\]\[$b\]"}
  }
}

# ---- s1_oldestSel 流水寄存器（3 路：valid + 7 位下标）----
for {set i 0} {$i < 3} {incr i} {
  catch {set_user_match "r:/WORK/$top/s1_oldestSel_${i}_valid_r_reg" \
                        "i:/WORK/$top/u_core/s1_oldestSel_valid_q_reg\[$i\]"}
  catch {set_user_match "r:/WORK/$top/s2_oldestSel_${i}_valid_r_reg" \
                        "i:/WORK/$top/u_core/s2_oldestSel_valid_q_reg\[$i\]"}
  for {set b 0} {$b < 7} {incr b} {
    catch {set_user_match "r:/WORK/$top/s1_oldestSel_${i}_bits_r_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s1_oldestSel_bits_q_reg\[$i\]\[$b\]"}
    catch {set_user_match "r:/WORK/$top/s2_oldestSel_${i}_bits_r_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_oldestSel_bits_q_reg\[$i\]\[$b\]"}
  }
}

# ---- 冷却计数器 / lastReplay（3 路）----
for {set i 0} {$i < 3} {incr i} {
  catch {set_user_match "r:/WORK/$top/lastReplay_${i}_reg" \
                        "i:/WORK/$top/u_core/lastReplay_q_reg\[$i\]"}
  for {set b 0} {$b < 4} {incr b} {
    catch {set_user_match "r:/WORK/$top/coldCounter_${i}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/coldCounter_reg\[$i\]\[$b\]"}
  }
}

# ---- redirect 打拍：golden 有 6 份同源副本（s0_can_go_REG/_1/_2 + s1_cancel_REG/_1/_2）
#      = RegNext(io_redirect_*)，可读核只留一份 redirect_*_q。多对一钉点：
#      FM 的 merge-duplicated-registers 会把 6 份塌成 1，钉过之后一致。
#      robIdx 是 packed {flag, value[7:0]} → 位[8]=flag、位[7:0]=value。----
foreach pfx {s0_can_go_REG s0_can_go_REG_1 s0_can_go_REG_2
             s1_cancel_REG s1_cancel_REG_1 s1_cancel_REG_2} {
  catch {set_user_match "r:/WORK/$top/${pfx}_valid_reg"            "i:/WORK/$top/u_core/redirect_valid_q_reg"}
  catch {set_user_match "r:/WORK/$top/${pfx}_bits_robIdx_flag_reg" "i:/WORK/$top/u_core/redirect_robIdx_q_reg\[8\]"}
  catch {set_user_match "r:/WORK/$top/${pfx}_bits_level_reg"       "i:/WORK/$top/u_core/redirect_level_q_reg"}
  for {set b 0} {$b < 8} {incr b} {
    catch {set_user_match "r:/WORK/$top/${pfx}_bits_robIdx_value_reg\[$b\]" \
                          "i:/WORK/$top/u_core/redirect_robIdx_q_reg\[$b\]"}
  }
}

# ---- ★G1 新增★ 入队侧 C_DM blocking 的「上一拍 D-channel」打拍寄存器。
#      golden 给每个 enq 口各一份：blocking_REG/_1（口0）、_2/_3（口1）、_4/_5（口2），
#      三对同源、逐位恒等。可读核也声明三份（tl_d_valid_q[w] / tl_d_mshrid_q[w]）——
#      ★一份都不许少★：合并成一份在仿真里永远看不出来（值一直相同），
#      但 FM 会把它配给 0 号口，另外两份 globally unmatched，下游成片失配。----
for {set i 0} {$i < 3} {incr i} {
  set gv [expr {$i == 0 ? "blocking_REG" : "blocking_REG_[expr {$i*2}]"}]
  set gi "blocking_REG_[expr {$i*2+1}]"
  catch {set_user_match "r:/WORK/$top/${gv}_reg" "i:/WORK/$top/u_core/tl_d_valid_q_reg\[$i\]"}
  for {set b 0} {$b < 4} {incr b} {
    catch {set_user_match "r:/WORK/$top/${gi}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/tl_d_mshrid_q_reg\[$i\]\[$b\]"}
  }
}

# ---- s2 流水的对称 cone-dead 寄存器（3 路）----
#  golden s2_replayCauses(口0 无后缀)/_1/_2 各 11 位，只有 bit[4] 被读
#  （forward_tlDchannel）；其余 10 位两侧都存都不读 = 对称 matched-unread。
#  s2_replayMSHRId 同理：输出只取 [3:0]，bit[4] 两侧都存不读。
#  逐位钉双射，让 FM 把它们配成 matched-unread（vmucp 打开时实开比较、全 passing）。
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

# ---- perf 两级流水（13 项；index 3 是 1 位 replay_full，其余 2 位）----
for {set k 0} {$k < 13} {incr k} {
  set gs [expr {$k == 0 ? "" : ""}]
  if {$k == 3} {
    catch {set_user_match "r:/WORK/$top/io_perf_3_value_REG_reg"   "i:/WORK/$top/u_core/perfFull0_reg"}
    catch {set_user_match "r:/WORK/$top/io_perf_3_value_REG_1_reg" "i:/WORK/$top/u_core/perfFull1_reg"}
  } else {
    for {set b 0} {$b < 2} {incr b} {
      catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_reg\[$b\]" \
                            "i:/WORK/$top/u_core/perfReg0_reg\[$k\]\[$b\]"}
      catch {set_user_match "r:/WORK/$top/io_perf_${k}_value_REG_1_reg\[$b\]" \
                            "i:/WORK/$top/u_core/perfReg1_reg\[$k\]\[$b\]"}
    }
  }
}

puts "LQR_PINS: applied"
