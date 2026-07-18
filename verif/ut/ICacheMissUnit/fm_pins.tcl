# ICacheMissUnit FM 钉点:
# 1) priorityFIFO regFiles ↔ pf_fifo_reg (命名/层次差异, 1:1, 按 unmatched_full.rpt 实际下标)。
# 2) MSHR 状态: impl 把 golden 每-MSHR 的 flush/fencei 两个寄存器(golden 里两者次态
#    函数完全相同=重复寄存器: fetch 变体都只由 io_fencei 置位, prefetch 变体都由
#    io_fencei|io_flush 置位)合并为单个 killed 位。签名分析在部分 MSHR 上把
#    flush/fencei/issue/way 交叉错配 → 先 undo 再按语义钉: flush_reg↔killed,
#    issue_reg↔issued, way_reg↔way; fencei_reg(flush_reg 的重复寄存器)交给
#    verification_merge_duplicated_registers 合并。
# 布局: impl mshr_reg[0..3]=fetchMSHRs 0..3, mshr_reg[4..13]=prefetchMSHRs 0..9。

# --- MSHR 全字段确定性钉点：先撤两侧全部自动匹配，再 1:1 钉死 ---
# (killed/killed2 是同函数重复寄存器，签名分析会与 golden flush/fencei 任意交叉配对，
#  留下 unmatched 残余成为锥输入毒化大片比对点；payload 各位也可能被交叉配对)
set _mshr_n 0; set _mshr_f 0
for {set k 0} {$k < 14} {incr k} {
  if {$k < 4} { set rp "fetchMSHRs_$k" } else { set rp "prefetchMSHRs_[expr {$k-4}]" }
  # 撤销 ref 侧
  foreach f {valid_reg flush_reg fencei_reg issue_reg} {
    catch {undo_match "r:/WORK/$top/$rp/$f"}
  }
  foreach b {0 1} { catch {undo_match "r:/WORK/$top/$rp/way_reg\[$b\]"} }
  for {set b 0} {$b < 42} {incr b} { catch {undo_match "r:/WORK/$top/$rp/blkPaddr_reg\[$b\]"} }
  for {set b 0} {$b < 8} {incr b} { catch {undo_match "r:/WORK/$top/$rp/vSetIdx_reg\[$b\]"} }
  # 撤销 impl 侧
  foreach f {valid killed killed2 issued} {
    catch {undo_match "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[$f]"}
  }
  foreach b {0 1} { catch {undo_match "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[way]\[$b\]"} }
  for {set b 0} {$b < 42} {incr b} { catch {undo_match "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[blkPaddr]\[$b\]"} }
  for {set b 0} {$b < 8} {incr b} { catch {undo_match "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[vSetIdx]\[$b\]"} }
  # 1:1 钉
  foreach {rf if_} [list valid_reg valid flush_reg killed fencei_reg killed2 issue_reg issued] {
    if {[catch {set_user_match "r:/WORK/$top/$rp/$rf" "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[$if_]"} msg]} {
      puts "MSHR_PIN_FAIL: $rp/$rf ($msg)"; incr _mshr_f
    } else { incr _mshr_n }
  }
  foreach b {0 1} {
    if {[catch {set_user_match "r:/WORK/$top/$rp/way_reg\[$b\]" "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[way]\[$b\]"} msg]} {
      puts "MSHR_PIN_FAIL: $rp/way_reg\[$b\] ($msg)"; incr _mshr_f
    } else { incr _mshr_n }
  }
  for {set b 0} {$b < 42} {incr b} {
    if {[catch {set_user_match "r:/WORK/$top/$rp/blkPaddr_reg\[$b\]" "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[blkPaddr]\[$b\]"} msg]} {
      puts "MSHR_PIN_FAIL: $rp/blkPaddr\[$b\] ($msg)"; incr _mshr_f
    } else { incr _mshr_n }
  }
  for {set b 0} {$b < 8} {incr b} {
    if {[catch {set_user_match "r:/WORK/$top/$rp/vSetIdx_reg\[$b\]" "i:/WORK/$top/u_core/mshr_reg\[$k\]\\\[vSetIdx]\[$b\]"} msg]} {
      puts "MSHR_PIN_FAIL: $rp/vSetIdx\[$b\] ($msg)"; incr _mshr_f
    } else { incr _mshr_f }
  }
}
puts "ICMU_MSHR_PINS: $_mshr_n pinned, $_mshr_f failed"

# --- priorityFIFO 指针(FIFOReg {flag,value} 方案与 impl pf_* 完全同构, 签名交叉错配) ---
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)" }
}
foreach {rl il} {
  enq_ptr_flag_reg pf_enq_flag_reg
  deq_ptr_flag_reg pf_deq_flag_reg
} {
  catch {undo_match "r:/WORK/$top/priorityFIFO/$rl"}
  catch {undo_match "i:/WORK/$top/u_core/$il"}
  _pin "r:/WORK/$top/priorityFIFO/$rl" "i:/WORK/$top/u_core/$il"
}
for {set b 0} {$b < 4} {incr b} {
  foreach {rl il} {enq_ptr_value pf_enq_ptr  deq_ptr_value pf_deq_ptr} {
    catch {undo_match "r:/WORK/$top/priorityFIFO/${rl}_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/${il}_reg\[$b\]"}
    _pin "r:/WORK/$top/priorityFIFO/${rl}_reg\[$b\]" "i:/WORK/$top/u_core/${il}_reg\[$b\]"
  }
}
puts "ICMU_FIFO_PINS: done"


# --- priorityFIFO regFiles 全量确定性钉点（10 项 × 4 位，先撤两侧再钉） ---
set _pf_n 0; set _pf_f 0
for {set e 0} {$e < 10} {incr e} {
  for {set b 0} {$b < 4} {incr b} {
    catch {undo_match "r:/WORK/$top/priorityFIFO/regFiles_${e}_reg\[$b\]"}
    catch {undo_match "i:/WORK/$top/u_core/pf_fifo_reg\[$e\]\[$b\]"}
  }
}
for {set e 0} {$e < 10} {incr e} {
  for {set b 0} {$b < 4} {incr b} {
    if {[catch {set_user_match "r:/WORK/$top/priorityFIFO/regFiles_${e}_reg\[$b\]" \
                              "i:/WORK/$top/u_core/pf_fifo_reg\[$e\]\[$b\]"} msg]} {
      puts "PF_PIN_FAIL: regFiles_${e}\[$b\] ($msg)"; incr _pf_f
    } else { incr _pf_n }
  }
}
puts "ICMU_PFFIFO_PINS: $_pf_n pinned, $_pf_f failed"
