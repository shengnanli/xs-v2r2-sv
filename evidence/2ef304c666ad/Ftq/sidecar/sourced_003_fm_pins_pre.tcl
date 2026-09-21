# Ftq FM 匹配前钉点 —— commitStateQueue 阵列的 64x16x2 双射（2026-09-14 诊断）
# ============================================================================
# 症状：signoff-strict 下 `make fm-Ftq` 报 20 个 failing、30(34) 个 unmatched
#       compare point，且 4251 个点落进 "Unverified"。20 不是真实失配数——
#       Formality 的 verification_failing_point_limit 默认就是 20，报满即停，
#       剩下的点全部变成 unverified（本例 2006 个 commitStateQueue 点在其中）。
#
# 匹配为什么会散：golden 的叶名是 firtool 展平出来的 commitStateQueueReg_<i>_<j>，
#       可读核是 SV 二维数组 commitStateQueue[<i>][<j>]——词干就不同
#       （...QueueReg vs ...Queue），fm_eq.tcl 里的 auto_match_flattened_arrays
#       按 name_i_j_reg 规约也对不上（实测 30 条 AUTO_MATCH_FAIL 全在这里）。
#       于是 2048 个位全靠签名分析配对；阵列各项逻辑高度对称，签名分析配错了一批，
#       留下 22(ref)/22(impl) 配不上的散点。
#
# 本钉点只做「名字对不上时的一一对应」：不 dont_verify、不加黑盒、不约束 ref。
# 若哪天可读核真把某一项写错了，钉成这个对应只会让 FM **失败**，不会掩盖问题。
# ============================================================================

if {$top eq "Ftq"} {
  # ★归因标记★：fm.log 里 OE_PIN_BEGIN..OE_PIN_END 之间的 `Error:` 行才是
  #   **本文件**的钉点失败；区间外的 FM-036 多半来自 match_packed_payload
  #   那类投机性试名。判据见 scripts/check_pin_errors.py。
  # ★为什么不再用 catch 数钉点★：set_user_match **从不抛异常**（名字不存在
  #   时返回 0 并往 fm.log 写 `Error: Unknown name: ... (FM-036)`），所以旧写法
  #   `if {[catch {set_user_match ...}]} {incr _miss} else {incr _n}` 的 else 支
  #   恒成立 —— _miss 恒 0、_n 恒等于尝试次数，两道守卫都是空的。
  #   现改为直接取返回值，并在文件末尾用 `error` fail-closed。
  #   ★用 `error` 不用 `exit`★：正式签核时本文件跑在 `interp create -safe`
  #   里（run_proof.sh 设 FM_SIDECAR_OUT），safe interp 隐藏 `exit`，
  #   只有 `error` 穿得出去。
  # ★3494 与 3488 是两个不同的量，别混★
  #   3494 = 本文件发出的 set_user_match **调用**数（本文件的守卫数的就是它）；
  #   3488 = match 之后 fm.log 里的 "Compare points matched by user"。
  #   差 6 = toPrefetchPc 的低 6 位：两侧都被 verification_merge_duplicated_registers
  #   合并掉（见下面 toPrefetchPc 那段的说明），钉的时候成功、match 后不各自成点。
  puts "OE_PIN_BEGIN Ftq expect=3494"
  set _n 0
  set _miss 0
  for {set i 0} {$i < 64} {incr i} {
    for {set j 0} {$j < 16} {incr j} {
      for {set b 0} {$b < 2} {incr b} {
        if {[set_user_match \
              "r:/WORK/$top/commitStateQueueReg_${i}_${j}_reg\[$b\]" \
              "i:/WORK/$top/u_core/commitStateQueue_reg\[$i\]\[$j\]\[$b\]"]} {
          incr _n
        } else {
          incr _miss
          if {$_miss <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/commitStateQueueReg_${i}_${j}_reg\[$b\]" }
        }
      }
    }
  }
  puts "FTQ_PINS: commitStateQueue bijection pinned=$_n miss=$_miss (expect 2048 / 0)"

  # golden 的 copied_last_cycle_bpu_in_REG_5/_6 是 commitStateQueue 清零专用的两份
  # 使能扇出复制（低 32 项 / 高 32 项各一份）。可读核同名同结构地实现了这两份，
  # 名字本可自动配上，这里显式钉死，避免签名分析把它与另外 5 份复制搅在一起。
  set _n2 0
  set _miss2 0
  foreach _s {5 6} {
    if {[set_user_match \
          "r:/WORK/$top/copied_last_cycle_bpu_in_REG_${_s}_reg" \
          "i:/WORK/$top/u_core/copied_last_cycle_bpu_in_REG_${_s}_reg"]} {
      incr _n2
    } else {
      incr _miss2
      if {$_miss2 <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/copied_last_cycle_bpu_in_REG_${_s}_reg" }
    }
  }
  puts "FTQ_PINS: copied_last_cycle_bpu_in_REG_5/6 pinned=$_n2 miss=$_miss2 (expect 2 / 0)"

  # 同一类"词干不同 → 名字匹配必然失败 → 只能靠签名分析"的每项阵列，一并钉死：
  #   golden mispredict_vec_<entry>_<slot>   ↔ 可读核 mispred_block[<entry>][<slot>]
  #   golden cfiIndex_vec_<entry>_valid/bits ↔ 可读核 cfiIndex_valid/cfiIndex_bits[<entry>]
  # 这三族（含上面的 commitStateQueue）合计 2048+1024+64+256 = 3392 个点，正好是
  # 本目标"签名分析配对"那一大块的主体；阵列各项逻辑对称，签名分析在这里没有判别力。
  set _n3 0
  set _miss3 0
  for {set i 0} {$i < 64} {incr i} {
    for {set j 0} {$j < 16} {incr j} {
      if {[set_user_match \
            "r:/WORK/$top/mispredict_vec_${i}_${j}_reg" \
            "i:/WORK/$top/u_core/mispred_block_reg\[$i\]\[$j\]"]} {
        incr _n3
      } else {
        incr _miss3
        if {$_miss3 <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/mispredict_vec_${i}_${j}_reg" }
      }
    }
    if {[set_user_match \
          "r:/WORK/$top/cfiIndex_vec_${i}_valid_reg" \
          "i:/WORK/$top/u_core/cfiIndex_valid_reg\[$i\]"]} {
      incr _n3
    } else {
      incr _miss3
      if {$_miss3 <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/cfiIndex_vec_${i}_valid_reg" }
    }
    for {set b 0} {$b < 4} {incr b} {
      if {[set_user_match \
            "r:/WORK/$top/cfiIndex_vec_${i}_bits_reg\[$b\]" \
            "i:/WORK/$top/u_core/cfiIndex_bits_reg\[$i\]\[$b\]"]} {
        incr _n3
      } else {
        incr _miss3
        if {$_miss3 <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/cfiIndex_vec_${i}_bits_reg\[$b\]" }
      }
    }
  }
  puts "FTQ_PINS: mispredict_vec + cfiIndex_vec pinned=$_n3 miss=$_miss3 (expect 1344 / 0)"

  # toPrefetchPcBundle/toPrefetchPc 两条 50 位流水寄存器逐位对齐（词干 Bundle 有无之差）。
  # 低 6 位两侧都会被 verification_merge_duplicated_registers 合并掉：
  # nextLineAddr = startAddr + 50'h40，进位碰不到 [5:0]，两条寄存器的第 0..5 位 D 输入
  # 是同一根 net，FM 只留一个代表（实测两侧留下的都是 nextLineAddr_reg[b]）。
  # 所以这 100 条 set_user_match 在钉的时候全成功，match 之后真正生效的是 94 条
  # （startAddr 的低 6 位随 ref/impl 两侧的代表一起被合并掉，属对称合并，不留残点）。
  # ★注意★：可读核必须显式让这低 6 位共用同一根 net（见 rtl/frontend/Ftq.sv 的
  # toPrefetchPc_nextLineAddr 赋值），否则只有 golden 侧合并、impl 侧多出 6 个无对象
  # 比对点，它们退化成自由变量，直接把 io_toPrefetch_req_bits_startAddr 低 6 位判失配
  # （实测 0(6) unmatched + 6 failing）。
  set _n4 0
  set _miss4 0
  foreach _f {startAddr nextLineAddr} {
    for {set b 0} {$b < 50} {incr b} {
      if {[set_user_match \
            "r:/WORK/$top/toPrefetchPcBundle_${_f}_reg\[$b\]" \
            "i:/WORK/$top/u_core/toPrefetchPc_${_f}_reg\[$b\]"]} {
        incr _n4
      } else {
        incr _miss4
        if {$_miss4 <= 10} { puts "FTQ_PIN_FAIL: r:/WORK/$top/toPrefetchPcBundle_${_f}_reg\[$b\]" }
      }
    }
  }
  puts "FTQ_PINS: toPrefetchPc startAddr/nextLineAddr pinned=$_n4 miss=$_miss4 (expect 100 / 0; match 后生效 94，低 6 位两侧对称合并)"

  # ---- fail-closed（都在最后一次 set_user_match 之后）----
  set _ntot   [expr {$_n + $_n2 + $_n3 + $_n4}]
  set _misstot [expr {$_miss + $_miss2 + $_miss3 + $_miss4}]
  puts "OE_PIN_END Ftq n=$_ntot miss=$_misstot expect=3494"
  if {$_misstot != 0} { error "FTQ_PIN_MISS=Ftq miss=$_misstot (n=$_ntot)" }
  if {$_ntot != 3494} { error "FTQ_PIN_COUNT=Ftq n=$_ntot expect=3494" }
  # 分族期望值（2048 + 2 + 1344 + 100 = 3494），任一族少配都要当场炸：
  if {$_n  != 2048} { error "FTQ_PIN_COUNT=commitStateQueue n=$_n expect=2048" }
  if {$_n2 != 2}    { error "FTQ_PIN_COUNT=copied_last_cycle_bpu_in n=$_n2 expect=2" }
  if {$_n3 != 1344} { error "FTQ_PIN_COUNT=mispredict/cfiIndex n=$_n3 expect=1344" }
  if {$_n4 != 100}  { error "FTQ_PIN_COUNT=toPrefetchPc n=$_n4 expect=100" }
}
