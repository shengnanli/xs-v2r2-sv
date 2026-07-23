# L2TLB FM 匹配前钉点（FM 审计 2026-07）
# golden 顶层 glue 的 mem-resp/refill 锁存寄存器 ↔ impl 数组/改名寄存器一一映射。
# 全部 catch 保护（点不存在则跳过）。
setup

set _n 0
proc pin {r i} {
  global _n
  if {![catch {set_user_match "r:/WORK/L2TLB/$r" "i:/WORK/L2TLB/u_core/$i"}]} { incr _n }
}

# ---- resp_pte_sector：8 id × 2 半块(256b)。golden 命名：id0 → r_0/r_1；id k≥1 → r_k_0/r_k_1 ----
for {set b 0} {$b < 256} {incr b} {
  pin "resp_pte_sector_r_0_reg\[$b\]" "resp_pte_sector_reg\[0\]\[$b\]"
  pin "resp_pte_sector_r_1_reg\[$b\]" "resp_pte_sector_reg\[0\]\[[expr {$b+256}]\]"
}
for {set k 1} {$k < 8} {incr k} {
  for {set b 0} {$b < 256} {incr b} {
    pin "resp_pte_sector_r_${k}_0_reg\[$b\]" "resp_pte_sector_reg\[$k\]\[$b\]"
    pin "resp_pte_sector_r_${k}_1_reg\[$b\]" "resp_pte_sector_reg\[$k\]\[[expr {$b+256}]\]"
  }
}

# ---- llptw mem resp 保持寄存器（均为 holdUnless(d_valid)、无复位）----
for {set b 0} {$b < 512} {incr b} {
  pin "llptw_io_mem_resp_bits_value_r_reg\[$b\]" "llptw_resp_value_r_reg\[$b\]"
}
# refill_data 双拍寄存器（有复位，两侧同名同构）
for {set b 0} {$b < 256} {incr b} {
  pin "refill_data_0_reg\[$b\]" "refill_data_reg\[0\]\[$b\]"
  pin "refill_data_1_reg\[$b\]" "refill_data_reg\[1\]\[$b\]"
}
for {set b 0} {$b < 3} {incr b} {
  pin "llptw_io_mem_resp_bits_id_r_reg\[$b\]" "llptw_resp_id_r_reg\[$b\]"
}

# ---- PTW/HPTW 单 PTE 暂存 ----
for {set b 0} {$b < 64} {incr b} {
  pin "resp_pte_r_6_reg\[$b\]" "resp_pte_ptw_reg\[$b\]"
  pin "resp_pte_r_7_reg\[$b\]" "resp_pte_hptw_reg\[$b\]"
}

# ---- cache.refill dup 锁存副本 ----
foreach {j} {0 1 2} {
  for {set b 0} {$b < 38} {incr b} {
    pin "cache_io_refill_bits_req_info_dup_${j}_r_vpn_reg\[$b\]" "refill_req_info_r_reg\[$j\]\\\[vpn\]\[$b\]"
  }
  for {set b 0} {$b < 2} {incr b} {
    pin "cache_io_refill_bits_req_info_dup_${j}_r_s2xlate_reg\[$b\]" "refill_req_info_r_reg\[$j\]\\\[s2xlate\]\[$b\]"
    pin "cache_io_refill_bits_req_info_dup_${j}_r_source_reg\[$b\]"  "refill_req_info_r_reg\[$j\]\\\[source\]\[$b\]"
  }
}
foreach {g k} {0 0 2 1} {
  for {set b 0} {$b < 2} {incr b} {
    pin "cache_io_refill_bits_level_dup_${g}_r_reg\[$b\]" "refill_level_r_reg\[$k\]\[$b\]"
  }
  for {set b 0} {$b < 64} {incr b} {
    pin "cache_io_refill_bits_sel_pte_dup_${g}_r_reg\[$b\]" "refill_sel_pte_r_reg\[$k\]\[$b\]"
  }
}
# levelOH 打拍
pin "cache_io_refill_bits_levelOH_sp_last_REG_reg" "lvOH_sp_r_reg"
pin "cache_io_refill_bits_levelOH_l0_last_REG_reg" "lvOH_l0_r_reg"
pin "cache_io_refill_bits_levelOH_l1_last_REG_reg" "lvOH_l1_r_reg"
pin "cache_io_refill_bits_levelOH_l2_last_REG_reg" "lvOH_l2_r_reg"
pin "cache_io_refill_bits_levelOH_l3_last_REG_reg" "lvOH_l3_r_reg"
pin "cache_io_refill_valid_last_REG_reg" "refill_valid_d_reg"

# ---- PTW/HPTW refill level RegEnable ----
for {set b 0} {$b < 2} {incr b} {
  pin "refill_level_r_reg\[$b\]"   "ptw_refill_level_r_reg\[$b\]"
  pin "refill_level_r_1_reg\[$b\]" "hptw_refill_level_r_reg\[$b\]"
}

puts "L2TLB_PINS: $_n points pinned"
