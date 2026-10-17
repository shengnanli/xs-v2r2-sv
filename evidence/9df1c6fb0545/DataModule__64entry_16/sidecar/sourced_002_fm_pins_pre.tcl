# 自动生成：scripts/gen_dm_wrappers.py —— banked 存储双射钉点（勿手改）
# 判据：set_user_match 的**返回值**（它对不存在的名字不抛异常，catch 是空守卫）；
# 末尾 miss 必须为 0、pinned 必须等于字面期望数（banks × 条目 × 位宽和），否则 error。

if {$top eq "SyncDataModuleTemplate_BackendPC_64entry"} {
  set _flds { {startAddr 0 50} }
  set _expect 3200
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate_FtqPC_64entry"} {
  set _flds { {startAddr 0 50} {nextLineAddr 50 50} {fallThruError 100 1} }
  set _expect 6464
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__1024entry"} {
  set _flds { {- 0 1} }
  set _expect 1024
  set _n 0; set _miss 0
  for {set b 0} {$b < 16} {incr b} {
    for {set e 0} {$e < 64} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry"} {
  set _flds { {histPtr_flag 0 1} {histPtr_value 1 8} {ssp 9 4} {sctr 13 3} {TOSW_flag 16 1} {TOSW_value 17 5} {TOSR_flag 22 1} {TOSR_value 23 5} {NOS_flag 28 1} {NOS_value 29 5} {topAddr 34 50} {sc_disagree_0 84 1} {sc_disagree_1 85 1} }
  set _expect 5504
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry_1"} {
  set _flds { {meta 0 516} {ftb_entry_isCall 516 1} {ftb_entry_isRet 517 1} {ftb_entry_isJalr 518 1} {ftb_entry_valid 519 1} {ftb_entry_brSlots_0_offset 520 4} {ftb_entry_brSlots_0_sharing 524 1} {ftb_entry_brSlots_0_valid 525 1} {ftb_entry_brSlots_0_lower 526 12} {ftb_entry_brSlots_0_tarStat 538 2} {ftb_entry_tailSlot_offset 540 4} {ftb_entry_tailSlot_sharing 544 1} {ftb_entry_tailSlot_valid 545 1} {ftb_entry_tailSlot_lower 546 20} {ftb_entry_tailSlot_tarStat 566 2} {ftb_entry_pftAddr 568 4} {ftb_entry_carry 572 1} {ftb_entry_last_may_be_rvi_call 573 1} {ftb_entry_strong_bias_0 574 1} {ftb_entry_strong_bias_1 575 1} }
  set _expect 36864
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry_2"} {
  set _flds { {isCall 0 1} {isRet 1 1} {isJalr 2 1} {brSlots_0_offset 3 4} {brSlots_0_valid 7 1} {tailSlot_offset 8 4} {tailSlot_sharing 12 1} {tailSlot_valid 13 1} }
  set _expect 896
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry_3"} {
  set _flds { {brMask_0 0 1} {brMask_1 1 1} {brMask_2 2 1} {brMask_3 3 1} {brMask_4 4 1} {brMask_5 5 1} {brMask_6 6 1} {brMask_7 7 1} {brMask_8 8 1} {brMask_9 9 1} {brMask_10 10 1} {brMask_11 11 1} {brMask_12 12 1} {brMask_13 13 1} {brMask_14 14 1} {brMask_15 15 1} {jmpInfo_valid 16 1} {jmpInfo_bits_0 17 1} {jmpInfo_bits_1 18 1} {jmpInfo_bits_2 19 1} {jmpOffset 20 4} {jalTarget 24 50} {rvcMask_0 74 1} {rvcMask_1 75 1} {rvcMask_2 76 1} {rvcMask_3 77 1} {rvcMask_4 78 1} {rvcMask_5 79 1} {rvcMask_6 80 1} {rvcMask_7 81 1} {rvcMask_8 82 1} {rvcMask_9 83 1} {rvcMask_10 84 1} {rvcMask_11 85 1} {rvcMask_12 86 1} {rvcMask_13 87 1} {rvcMask_14 88 1} {rvcMask_15 89 1} }
  set _expect 5760
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry_4"} {
  set _flds { {vtype_illegal 0 1} {vtype_vma 1 1} {vtype_vta 2 1} {vtype_vsew 3 2} {vtype_vlmul 5 3} {isVsetvl 8 1} }
  set _expect 576
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}

if {$top eq "SyncDataModuleTemplate__64entry_5"} {
  set _flds { {gpaddr 0 56} {isForVSnonLeafPTE 56 1} }
  set _expect 3648
  set _n 0; set _miss 0
  for {set b 0} {$b < 4} {incr b} {
    for {set e 0} {$e < 16} {incr e} {
      foreach _f $_flds {
        lassign $_f suf off w
        set stem [expr {$suf eq "-" ? "data_${e}" : "data_${e}_${suf}"}]
        for {set k 0} {$k < $w} {incr k} {
          if {$w == 1} {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg"
          } else {
            set rp "r:/WORK/$top/dataBanks_${b}/${stem}_reg\[$k\]"
          }
          set ipath "i:/WORK/$top/u_core/g_bank\[$b\].dataBank/data_reg\[$e\]\[[expr {$off+$k}]\]"
          if {[set_user_match $rp $ipath]} {
            incr _n
          } else {
            incr _miss
            if {$_miss <= 10} { puts "SDM_PIN_FAIL($top): $rp <-> $ipath" }
          }
        }
      }
    }
  }
  puts "SDM_PIN($top): pinned=$_n miss=$_miss expect=$_expect"
  if {$_miss != 0 || $_n != $_expect} {
    error "SDM_PIN_COUNT($top): pinned=$_n miss=$_miss expect=$_expect"
  }
}
