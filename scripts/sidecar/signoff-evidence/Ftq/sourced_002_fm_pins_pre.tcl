# Ftq FM 匹配前钉点（FM 审计 2026-07）
# golden 逐 entry/逐槽展平命名 ↔ impl 数组寄存器命名的一一映射；签名分析在这些
# 对称阵列上常错配，match 前显式 set_user_match 钉死。全部 catch 保护（点不存在则跳过）。
setup

set _n 0
proc pin {r i} {
  global _n
  if {![catch {set_user_match "r:/WORK/Ftq/$r" "i:/WORK/Ftq/u_core/$i"}]} { incr _n }
}

# ---- 指针主寄存器锚点（在 copied_* 复制之前显式钉，防 merge 把 ifuPtr 代表让给
#      impl 新增 copied_ifu_ptr_reg[0]→ifuPtr/ifuPtrPlus1/ifuPtrPlus2/entry_hit_status 失配）----
foreach {gp ip} {ifuPtr ifuPtr ifuPtrPlus1 ifuPtrPlus1 ifuPtrPlus2 ifuPtrPlus2 bpuPtr bpuPtr pfPtr pfPtr} {
  pin "${gp}_flag_reg" "${ip}_reg\[6\]"
  for {set b 0} {$b < 6} {incr b} { pin "${gp}_value_reg\[$b\]" "${ip}_reg\[$b\]" }
}
# last_cycle_to_ifu_fire 单副本锚点（防 merge 让给 copied_last_cycle_to_ifu_fire_REG[0]）
pin "last_cycle_to_ifu_fire_reg" "last_cycle_to_ifu_fire_reg"

# ---- 64 项 FTQ 阵列 ----
for {set n 0} {$n < 64} {incr n} {
  # cfiIndex：valid + 4 位 bits
  pin "cfiIndex_vec_${n}_valid_reg" "cfiIndex_valid_reg\[$n\]"
  for {set b 0} {$b < 4} {incr b} {
    pin "cfiIndex_vec_${n}_bits_reg\[$b\]" "cfiIndex_bits_reg\[$n\]\[$b\]"
  }
  # mispredict_vec：16 槽
  for {set j 0} {$j < 16} {incr j} {
    pin "mispredict_vec_${n}_${j}_reg" "mispred_block_reg\[$n\]\[$j\]"
  }
  # commitStateQueueReg：16 槽 × 2 位
  for {set j 0} {$j < 16} {incr j} {
    for {set b 0} {$b < 2} {incr b} {
      pin "commitStateQueueReg_${n}_${j}_reg\[$b\]" "commitStateQueue_reg\[$n\]\[$j\]\[$b\]"
    }
  }
  # entry 状态
  pin "entry_fetch_status_${n}_reg" "entry_fetch_status_reg\[$n\]"
  for {set b 0} {$b < 2} {incr b} {
    pin "entry_hit_status_${n}_reg\[$b\]" "entry_hit_status_reg\[$n\]\[$b\]"
  }
}

# ---- toIfu PC 打拍（pc_mem 读出寄存）----
for {set b 0} {$b < 50} {incr b} {
  pin "pc_mem_ifu_ptr_rdata_REG_1_nextLineAddr_reg\[$b\]"   "toIfuPc_cur_nextLineAddr_reg\[$b\]"
  pin "pc_mem_ifu_plus1_rdata_REG_1_nextLineAddr_reg\[$b\]" "toIfuPc_p1_nextLineAddr_reg\[$b\]"
  pin "pc_mem_ifu_ptr_rdata_REG_1_startAddr_reg\[$b\]"      "toIfuPc_cur_startAddr_reg\[$b\]"
  pin "pc_mem_ifu_plus1_rdata_REG_1_startAddr_reg\[$b\]"    "toIfuPc_p1_startAddr_reg\[$b\]"
  pin "pc_mem_ifu_ptr_rdata_REG_startAddr_reg\[$b\]"        "toIfuPc_cur_startAddr_reg\[$b\]"
  pin "pc_mem_ifu_plus1_rdata_REG_startAddr_reg\[$b\]"      "toIfuPc_p1_startAddr_reg\[$b\]"
}

# ---- toICache 5 份扇出复制：★仅钉 FM 不会自动合并的 6 族★（copy0 无后缀 → g=""）----
#   golden copy N: copied_*(bare)=copy0, copied_*_1=copy1 ... _4=copy4
#   impl: 上面 g_icache_copy 阵列，copied_*_reg[N]（打包 [6:0] 的 ptr 用 [N][b]）
#   ★不钉 pc_mem_ifu_ptr/plus1_rdata_REG_N 与 copied_ifu/plus1_to_send_REG_N——它们会自动
#     并入 toIfuPc_cur/p1、entry_send_* 单副本（钉了反与 merge 冲突）。
proc gcp {n} { return [expr {$n==0 ? "" : "_$n"}] }
for {set n 0} {$n < 5} {incr n} {
  set g [gcp $n]
  # copied_ifu_ptr / copied_bpu_ptr / copied_bpu_in_bypass_ptr_r（golden flag+value 分离 ↔ impl 打包 [6:0]）
  pin "copied_ifu_ptr_${n}_flag_reg" "copied_ifu_ptr_reg\[$n\]\[6\]"
  pin "copied_bpu_ptr_${n}_flag_reg" "copied_bpu_ptr_reg\[$n\]\[6\]"
  pin "copied_bpu_in_bypass_ptr_r${g}_flag_reg" "copied_bpu_in_bypass_ptr_r_reg\[$n\]\[6\]"
  for {set b 0} {$b < 6} {incr b} {
    pin "copied_ifu_ptr_${n}_value_reg\[$b\]"           "copied_ifu_ptr_reg\[$n\]\[$b\]"
    pin "copied_bpu_ptr_${n}_value_reg\[$b\]"           "copied_bpu_ptr_reg\[$n\]\[$b\]"
    pin "copied_bpu_in_bypass_ptr_r${g}_value_reg\[$b\]" "copied_bpu_in_bypass_ptr_r_reg\[$n\]\[$b\]"
  }
  # copied_bpu_in_bypass_buf_r（50 位 startAddr/nextLineAddr）
  for {set b 0} {$b < 50} {incr b} {
    pin "copied_bpu_in_bypass_buf_r${g}_startAddr_reg\[$b\]"    "copied_bpu_in_bypass_buf_r_startAddr_reg\[$n\]\[$b\]"
    pin "copied_bpu_in_bypass_buf_r${g}_nextLineAddr_reg\[$b\]" "copied_bpu_in_bypass_buf_r_nextLineAddr_reg\[$n\]\[$b\]"
  }
  # copied_last_cycle_bpu_in_REG / copied_last_cycle_to_ifu_fire_REG（1 位）
  pin "copied_last_cycle_bpu_in_REG${g}_reg"      "copied_last_cycle_bpu_in_REG_reg\[$n\]"
  pin "copied_last_cycle_to_ifu_fire_REG${g}_reg" "copied_last_cycle_to_ifu_fire_REG_reg\[$n\]"
}
# 注意 golden toIfuPcBundle_REG 命名与 pc_mem_ifu_ptr_rdata_REG 相反：
#   toIfuPcBundle_REG      <= ifuPtrPlus1_rdata  → impl toIfuPc_p1 (Plus1)
#   toIfuPcBundle_REG_1    <= ifuPtr_rdata       → impl toIfuPc_cur (ifuPtr)
# 原钉点写反(REG→cur/REG_1→p1)=把 Plus1 源钉到 ifuPtr 目标→值不等→fallThruErr 失配
#   →传染 toIfu_fallThruErr→has_false_hit→entry_hit_status 128 点全 fail。
pin "toIfuPcBundle_REG_fallThruError_reg"   "toIfuPc_p1_fallThruErr_reg"
pin "toIfuPcBundle_REG_1_fallThruError_reg" "toIfuPc_cur_fallThruErr_reg"

# 注: golden copied_ifu_ptr_N 等 6 族现钉到 impl 新增复制阵列 copied_*_reg[N]（见上方
#   g_icache_copy），★不再钉到 impl ifuPtr/bpuPtr★（那会抢占单副本配对）。这些复制阵列
#   next-state 与 ifuPtr/bpuPtr/bpu_in_bypass_*/last_cycle_* 逐位相同，pcMemRead/readValid
#   端口锥两侧 1:1 等价。

# ---- commit 目标打拍 ----
pin "commit_target_REG_reg" "commit_newest_eq_reg"
for {set b 0} {$b < 50} {incr b} {
  pin "commit_target_r_reg\[$b\]"     "commit_newest_target_reg\[$b\]"
  pin "commit_target_REG_1_reg\[$b\]" "commit_pc_p1_startAddr_r_reg\[$b\]"
}
# commit_mispredict 原始锁存
for {set j 0} {$j < 16} {incr j} {
  pin "commit_mispredict_r_${j}_reg" "commit_mispred_raw_reg\[$j\]"
}
# pd 打拍（false-hit 检测）
for {set j 0} {$j < 16} {incr j} {
  pin "pd_reg_${j}_valid_reg"  "pd_reg_valid_reg\[$j\]"
  pin "pd_reg_${j}_isRVC_reg"  "pd_reg_isRVC_reg\[$j\]"
  pin "pd_reg_${j}_isCall_reg" "pd_reg_isCall_reg\[$j\]"
  pin "pd_reg_${j}_isRet_reg"  "pd_reg_isRet_reg\[$j\]"
  for {set b 0} {$b < 2} {incr b} {
    pin "pd_reg_${j}_brType_reg\[$b\]" "pd_reg_brType_reg\[$j\]\[$b\]"
  }
}

# ---- BPU 旁路缓冲 ----
for {set b 0} {$b < 50} {incr b} {
  pin "bpu_in_bypass_buf_startAddr_reg\[$b\]"    "bpu_in_bypass_startAddr_reg\[$b\]"
  pin "bpu_in_bypass_buf_nextLineAddr_reg\[$b\]" "bpu_in_bypass_nextLineAddr_reg\[$b\]"
}
pin "bpu_in_bypass_buf_fallThruError_reg" "bpu_in_bypass_fallThruErr_reg"
pin "bpu_in_bypass_ptr_flag_reg" "bpu_in_bypass_ptr_reg\[6\]"
for {set b 0} {$b < 6} {incr b} {
  pin "bpu_in_bypass_ptr_value_reg\[$b\]" "bpu_in_bypass_ptr_reg\[$b\]"
}

# ---- newest entry ----
pin "newest_entry_ptr_flag_reg" "newest_entry_ptr_reg\[6\]"
for {set b 0} {$b < 6} {incr b} {
  pin "newest_entry_ptr_value_reg\[$b\]" "newest_entry_ptr_reg\[$b\]"
}
pin "newest_entry_en_reg" "newest_en_q1_reg"
for {set b 0} {$b < 50} {incr b} {
  pin "newest_entry_target_reg\[$b\]" "newest_entry_target_reg\[$b\]"
}

# ---- topdown / perf（本轮新实现的寄存器）----
for {set k 0} {$k < 38} {incr k} {
  pin "topdown_stage_reasons_${k}_reg" "topdown_stage_reasons_reg\[$k\]"
}
# 1 位事件：0..7 → perf_b[0..7]；22,23 → perf_b[8,9]
foreach {ev idx} {0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 22 8 23 9} {
  pin "io_perf_${ev}_value_REG_reg"   "perf_b_q1_reg\[$idx\]"
  pin "io_perf_${ev}_value_REG_1_reg" "perf_b_q2_reg\[$idx\]"
}
# 5 位事件：8..21 → perf_c[0..13]
for {set ev 8} {$ev < 22} {incr ev} {
  set idx [expr {$ev - 8}]
  for {set b 0} {$b < 5} {incr b} {
    pin "io_perf_${ev}_value_REG_reg\[$b\]"   "perf_c_q1_reg\[$idx\]\[$b\]"
    pin "io_perf_${ev}_value_REG_1_reg\[$b\]" "perf_c_q2_reg\[$idx\]\[$b\]"
  }
}

# ---- redirect 冲刷 commitStateQueue 打拍（golden r_2_* 副本 / flushItSelf_1）----
pin "hit_pd_mispred_reg_reg" "hit_pd_mispred_reg_reg"
for {set b 0} {$b < 6} {incr b} {
  pin "wb_idx_reg_reg\[$b\]" "wb_idx_reg_reg\[$b\]"
}

# ---- golden 匿名 REG*/r 寄存器 ↔ impl 具名寄存器（firtool 给这些 RegNext/RegEnable
#      起了无语义的 REG/REG_N/r 名字，签名/命名两法都配不上，须显式钉死；否则它们留作
#      未匹配 ref DFF = 自由变量，污染 mispred_block / commitStateQueue-flush / false-hit 锥）----
pin "REG_reg"    "last2_bpu_in_reg"           ;# REG  = RegNext(last_cycle_bpu_in)
pin "REG_1_reg"  "hit_pd_valid_reg_reg"       ;# REG_1= RegNext(hit_pd_valid)
pin "REG_4_reg"  "flush_csq_valid_q_reg"      ;# REG_4= RegNext(io_icacheFlush_0=redir_any)
pin "REG_10_reg" "flush_csq_flushItself_q_reg";# REG_10=RegNext(flushItSelf)
for {set b 0} {$b < 6} {incr b} {
  pin "r_reg\[$b\]"     "last2_bpu_in_ptr_reg\[$b\]"   ;# r    = RegEnable(last_cycle_bpu_in_ptr_value)
  pin "REG_6_reg\[$b\]" "flush_csq_idx_q_reg\[$b\]"    ;# REG_6= RegNext(redir_idx.value)
}
for {set b 0} {$b < 4} {incr b} {
  pin "REG_11_reg\[$b\]" "flush_csq_off_q_reg\[$b\]"   ;# REG_11=RegNext(redir_offset)
}

puts "FTQ_PINS: $_n points pinned"
