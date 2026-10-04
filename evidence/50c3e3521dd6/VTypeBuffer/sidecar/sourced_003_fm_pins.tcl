# VTypeBuffer FM「匹配后」钉点（FM_PIN_TCL）—— 手写，无生成器。
#
# 钉什么、为什么：诊断跑（FM_MERGE_DUP=false，vmucp=false）里 150 对 unmatched unread，全是两侧对称的
# 无读者寄存器位，因数组/平铺命名差异 FM 按名配不上、又无扇出可做签名分析：
#   (a) deqPtrVec_1..7（flag 1 + value 6 位 ×7 = 49）：Scala dontTouch(deqPtrVec) 留下，只有
#       deqPtrVec_0 被读（deqPtrVecNext 由队头推出）。
#       ref r:/WORK/VTypeBuffer/deqPtrVec_<i>_{flag_reg | value_reg[k]}
#       impl i:/WORK/VTypeBuffer/u_core/{deqPtrVec_flag_reg[i] | deqPtrVec_value_reg[i][k]}
#   (b) enqPtrVec_1..5 的 flag（5）：写地址只用 value，flag 只有 enqPtrVec_0 的被读。
#       ref enqPtrVec_<i>_flag_reg  <->  impl u_core/enqPtrVec_flag_reg[i]
#   (c) 子模块 SyncDataModuleTemplate__64entry_4 内（96）：每 bank 的读地址副本只用低 4 位
#       （bank 内 16 项）⇒ [5:4] 无读者（4 bank × 8 口 × 2 = 64）；每读口的 bank 选择寄存器只用
#       [5:4] ⇒ [3:0] 无读者（8 口 × 4 = 32）。golden 命名：bank0 为 raddr_dup_<p>，bank b≥1 为
#       raddr_dup_<b>_<p>；读口选择 p=0..3 为 raddr_dup_<4+p>_0，p=4..7 为 raddr_dup_<4+p>。
#       impl：u_core/vtypeBuffer/u_core/g_bank[b].raddr_dup_reg[p][bit]、g_rport[p].raddr_q_reg[bit]。
#   另有 deqPtrOH 64 位是 matched_nc（FM 自己按名配上），不在这里钉。
# 钉完交 vmucp 实比（白名单 verif/fm_target_config/VTypeBuffer.tcl）——加强，不是放过。
# fail-closed：set_user_match 不抛异常（返回 0 = 没配上），逐条数返回值；总数必须正好 150。
# 进 fm.log 的输出一律 ASCII。

if {$top eq "VTypeBuffer"} {
  set ::VTB_PIN_OK 0
  set ::VTB_PIN_BAD 0
  proc vtb_pin {r i} {
    if {[set_user_match $r $i]} { incr ::VTB_PIN_OK } else {
      incr ::VTB_PIN_BAD
      if {$::VTB_PIN_BAD <= 10} { puts "VTB_PIN_FAIL: $r <-> $i" }
    }
  }
  set R "r:/WORK/VTypeBuffer"
  set I "i:/WORK/VTypeBuffer/u_core"
  # (a) deqPtrVec_1..7
  for {set n 1} {$n < 8} {incr n} {
    vtb_pin "$R/deqPtrVec_${n}_flag_reg" "$I/deqPtrVec_flag_reg\[$n\]"
    for {set k 0} {$k < 6} {incr k} {
      vtb_pin "$R/deqPtrVec_${n}_value_reg\[$k\]" "$I/deqPtrVec_value_reg\[$n\]\[$k\]"
    }
  }
  # (b) enqPtrVec_1..5 flag
  for {set n 1} {$n < 6} {incr n} {
    vtb_pin "$R/enqPtrVec_${n}_flag_reg" "$I/enqPtrVec_flag_reg\[$n\]"
  }
  # (c) 存储体读地址寄存器的死位
  for {set b 0} {$b < 4} {incr b} {
    for {set p 0} {$p < 8} {incr p} {
      set g [expr {$b == 0 ? "raddr_dup_${p}" : "raddr_dup_${b}_${p}"}]
      foreach k {4 5} {
        vtb_pin "$R/vtypeBuffer/${g}_reg\[$k\]" "$I/vtypeBuffer/u_core/g_bank\[$b\].raddr_dup_reg\[$p\]\[$k\]"
      }
    }
  }
  for {set p 0} {$p < 8} {incr p} {
    set n [expr {4 + $p}]
    set g [expr {$p < 4 ? "raddr_dup_${n}_0" : "raddr_dup_${n}"}]
    for {set k 0} {$k < 4} {incr k} {
      vtb_pin "$R/vtypeBuffer/${g}_reg\[$k\]" "$I/vtypeBuffer/u_core/g_rport\[$p\].raddr_q_reg\[$k\]"
    }
  }
  puts "VTB_PINS: $::VTB_PIN_OK / 150 bad=$::VTB_PIN_BAD"
  if {$::VTB_PIN_BAD != 0 || $::VTB_PIN_OK != 150} {
    error "VTB_PIN_COUNT ok=$::VTB_PIN_OK bad=$::VTB_PIN_BAD expect=150"
  }
}
