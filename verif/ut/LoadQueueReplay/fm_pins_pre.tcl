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

# ---------------------------------------------------------------------------
# 钉点必须 fail-closed（2026-09-20 实测；改法与 gen_rob_pins.py 同源）
#
# 原先每条钉点都是裸的 catch + set_user_match，失败一声不吭。第一次真跑的后果：
# **573 条钉点被 FM 拒**（FM-036 Unknown name），fm.log 里刷了 573 行
# "Error: Unknown name: ..."，而脚本照常跑完、还打了 "LQR_PINS: applied"。
#
# 真实原因是**名字形状猜错**，不是 RTL 有问题。下面这些形状是从本轮
# matched.rpt 里逐条读出来的（不是猜的）：
#   · 非打包数组 + 纯向量元素（cause / missMSHRId / debug_vaddr / s2_cause_q ...）
#       i:/.../cause_reg[5][3]                          <- 原样可用
#   · 非打包数组 + **packed struct** 元素（ent / blockSqIdx / red_q_s*）
#       i:/.../ent_reg[0]\[allocated]                   <- 字段名下标，且带一个反斜杠
#       i:/.../blockSqIdx_reg[0]\[value][0]             <- 字段名带 \，数字下标不带
#       i:/.../red_q_s0_reg[0]\[robIdx]\[value][3]
#     ent_reg[$n]\[allocated] 当初蒙对了，blockSqIdx / red_q 这两族全错。
#
# 这 570 个点最后**还是被自动匹配配上了**（blockSqIdx 走 Name、red_q 走 Func），
# 所以第一版的结论不受影响 —— 但那是运气，不是判据。钉点被拒却静默退回自动匹配，
# 正是「闸不出声就不是闸」。改成：拒一条就 exit 3，并指名道姓第一条是哪一对。
#
# ★进 fm.log 的 puts 一律 ASCII★（CONVENTIONS：fm.log 不是 UTF-8，中文全成问号）。
# ---------------------------------------------------------------------------
# ★set_user_match 从不抛 Tcl 异常★（2026-09-20 用两容器最小设计实测）：
#     名字都在   -> 返回 1
#     名字不存在 -> 返回 0，并往 fm.log 写行首 `Error: Unknown name: ... (FM-036)`
#     catch {...} 恒为 0，msg 就是那个返回值本身
#   所以上一版写的 `if {[catch {set_user_match ...}]} {incr BAD} else {incr OK}`
#   里 BAD **恒为 0**、末尾那条 `exit 3` **一行都执行不到** ——
#   日志上那个 `rejected=0` 是恒真的，不是测出来的。
#   ★我当时还为它做过"双向负测"，但桩是 `error ...`，模拟的是一个不存在的行为，
#    于是那个负测只证明了"如果它抛异常我就能抓到"，而它不抛。★
#   判据的负测必须照着**真命令的真行为**建模，否则负测本身就是空的。
set ::LQR_PIN_EXPECT 6290
set ::LQR_PIN_OK 0
set ::LQR_PIN_BAD 0
set ::LQR_PIN_FIRSTBAD ""
proc pin {r i} {
  if {[set_user_match $r $i]} {
    incr ::LQR_PIN_OK
  } else {
    incr ::LQR_PIN_BAD
    if {$::LQR_PIN_BAD <= 10} { puts "LQR_PIN_FAIL: $r <-> $i" }
    if {$::LQR_PIN_FIRSTBAD eq ""} { set ::LQR_PIN_FIRSTBAD "$r <-> $i" }
  }
}
# ★标记★：fm.log 里 LQR_PIN_BEGIN 与 LQR_PIN_END 之间的 `Error:` 行才归本文件，
#  供 scripts/check_pin_errors.py --marker LQR_PIN 按区间归因。
puts "LQR_PIN_BEGIN LoadQueueReplay expect=$::LQR_PIN_EXPECT"

# ★2026-09-20 删掉了这里原有的两行 set_app_var，理由是实测的★
#   原文：set_app_var verification_assume_reg_init      none    （默认 Auto）
#         set_app_var verification_set_undriven_signals BINARY  （默认 binary:X）
#   核过 scripts/fm_eq.tcl：它自己一个都不设 ⇒ 这两行是唯一来源，
#   receipt 的 entry_appvars_readback 读回 None / BINARY 与之一致。
#   ★appvar 是判据的一部分，改它必须双向负测（CONVENTIONS）。这两行没有。★
#   我补测的结果（evidence 见 docs/loadqueuereplay_fm_prereg.md）：
#     · verification_set_undriven_signals：BINARY **不等于**默认 binary:X
#       （get_app_var 读回逐字不同）。用 Rob 那套四跑探针扩到三档实测：
#         ref 真逻辑 / ref 死驱动 x {binary:X, BINARY, 0}
#       binary:X 与 BINARY 两档**行为完全相同**（都抓到 impl 漏驱动），
#       只有 0 那档把死驱动那格遮住（复现 Rob 的结论）。
#       ⇒ 没有证据说 BINARY 是放宽，也没有证据说它有用。
#     · verification_assume_reg_init：我造了两个探针（初值不同的从不写寄存器、
#       ref 寄存器 vs impl 折成常量），**两个都分辨不出 Auto 与 None**
#       ⇒ 我手上没有任何证明 `none` 是加强的证据。我先前报告里说它"方向上是加强"
#       是**没有测量支撑的推断**，这里更正。
#   两个知识都指向同一处置：**去掉**，回到工具默认，并**重跑出证**
#   （删了不重跑 = 改了证明输入而证据没动）。run #4 就是那次重跑。

# ---- entry 控制位（1 位 × 72 × 4 个字段）----
foreach {gf if} {
  allocated allocated
  scheduled scheduled
  blocking  blocking
  strict    strict
} {
  for {set n 0} {$n < 72} {incr n} {
    pin "r:/WORK/$top/${gf}_${n}_reg" \
                          "i:/WORK/$top/u_core/ent_reg\[$n\]\\\[$if\]"
  }
}

# ---- dataInLastBeat（1 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  pin "r:/WORK/$top/dataInLastBeatReg_${n}_reg" \
                        "i:/WORK/$top/u_core/dataInLastBeat_reg\[$n\]"
}

# ---- s0_loadFreeSelMask_next_r（72 位）----
for {set b 0} {$b < 72} {incr b} {
  pin "r:/WORK/$top/s0_loadFreeSelMask_next_r_reg\[$b\]" \
                        "i:/WORK/$top/u_core/loadFreeSelMask_q_reg\[$b\]"
}

# ---- missMSHRId / tlbHintId（两侧都是 5 位：4 位端口零扩展）----
#  bit[4] 恒 0 但 golden 在 `==` 比较里**读**它，是个 compare point（0==0 passing）。
#  逐位 1:1 钉满 [4:0]，否则 golden 的 bit[4] 成 unmatched compare_ref。
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 5} {incr b} {
    pin "r:/WORK/$top/missMSHRId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/missMSHRId_reg\[$n\]\[$b\]"
    pin "r:/WORK/$top/tlbHintId_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/tlbHintId_reg\[$n\]\[$b\]"
  }
}

# ---- cause（11 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 11} {incr b} {
    pin "r:/WORK/$top/cause_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/cause_reg\[$n\]\[$b\]"
  }
}

# ---- debug_vaddr（50 位 × 72）----
for {set n 0} {$n < 72} {incr n} {
  for {set b 0} {$b < 50} {incr b} {
    pin "r:/WORK/$top/debug_vaddr_${n}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/debug_vaddr_reg\[$n\]\[$b\]"
  }
}

# ---- blockSqIdx（packed {flag, value[5:0]} × 72）----
for {set n 0} {$n < 72} {incr n} {
  pin "r:/WORK/$top/blockSqIdx_${n}_flag_reg" \
      "i:/WORK/$top/u_core/blockSqIdx_reg\[$n\]\\\[flag\]"
  for {set b 0} {$b < 6} {incr b} {
    pin "r:/WORK/$top/blockSqIdx_${n}_value_reg\[$b\]" \
        "i:/WORK/$top/u_core/blockSqIdx_reg\[$n\]\\\[value\]\[$b\]"
  }
}

# ---- s1_oldestSel 流水寄存器（3 路：valid + 7 位下标）----
for {set i 0} {$i < 3} {incr i} {
  pin "r:/WORK/$top/s1_oldestSel_${i}_valid_r_reg" \
                        "i:/WORK/$top/u_core/s1_oldestSel_valid_q_reg\[$i\]"
  pin "r:/WORK/$top/s2_oldestSel_${i}_valid_r_reg" \
                        "i:/WORK/$top/u_core/s2_oldestSel_valid_q_reg\[$i\]"
  for {set b 0} {$b < 7} {incr b} {
    pin "r:/WORK/$top/s1_oldestSel_${i}_bits_r_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s1_oldestSel_bits_q_reg\[$i\]\[$b\]"
    pin "r:/WORK/$top/s2_oldestSel_${i}_bits_r_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_oldestSel_bits_q_reg\[$i\]\[$b\]"
  }
}

# ---- 冷却计数器 / lastReplay（3 路）----
for {set i 0} {$i < 3} {incr i} {
  pin "r:/WORK/$top/lastReplay_${i}_reg" \
                        "i:/WORK/$top/u_core/lastReplay_q_reg\[$i\]"
  for {set b 0} {$b < 4} {incr b} {
    pin "r:/WORK/$top/coldCounter_${i}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/coldCounter_reg\[$i\]\[$b\]"
  }
}

# ---- redirect 打拍：golden 有 **6 份**同源副本，每路各一份、分两组：
#      s0_can_go_REG{,_1,_2} 喂 s0_can_go 那条锥，s1_cancel_REG{,_1,_2} 喂 s1_cancel。
#      六份逐位恒等。可读核也声明 6 份（red_q_s0[3] / red_q_s1[3]），1:1 钉。
#      ★上一版这里是 6 对 1（指望 merge-dup 把 6 份塌成 1），实测 FM match 报
#       55 个 unmatched（5 份副本 ×11 位，全在 ref 侧、impl 侧 0 个）。
#       未配对的比较点是自由割点，下游整条锥会跟着失配 —— 所以改成逐份 1:1。★
#      impl 的 redirect_q_t 是 packed {valid, robIdx{flag,value[7:0]}, level}
#      → 位[10]=valid、位[9]=robIdx.flag、位[8:1]=robIdx.value、位[0]=level。
foreach {gpfx iarr} {s0_can_go_REG red_q_s0  s1_cancel_REG red_q_s1} {
  for {set i 0} {$i < 3} {incr i} {
    set gs [expr {$i == 0 ? "" : "_$i"}]
    pin "r:/WORK/$top/${gpfx}${gs}_valid_reg" \
        "i:/WORK/$top/u_core/${iarr}_reg\[$i\]\\\[valid\]"
    pin "r:/WORK/$top/${gpfx}${gs}_bits_robIdx_flag_reg" \
        "i:/WORK/$top/u_core/${iarr}_reg\[$i\]\\\[robIdx\]\\\[flag\]"
    pin "r:/WORK/$top/${gpfx}${gs}_bits_level_reg" \
        "i:/WORK/$top/u_core/${iarr}_reg\[$i\]\\\[level\]"
    for {set b 0} {$b < 8} {incr b} {
      pin "r:/WORK/$top/${gpfx}${gs}_bits_robIdx_value_reg\[$b\]" \
          "i:/WORK/$top/u_core/${iarr}_reg\[$i\]\\\[robIdx\]\\\[value\]\[$b\]"
    }
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
  pin "r:/WORK/$top/${gv}_reg" "i:/WORK/$top/u_core/tl_d_valid_q_reg\[$i\]"
  for {set b 0} {$b < 4} {incr b} {
    pin "r:/WORK/$top/${gi}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/tl_d_mshrid_q_reg\[$i\]\[$b\]"
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
    pin "r:/WORK/$top/s2_replayCauses${gsuf}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_cause_q_reg\[$i\]\[$b\]"
  }
  for {set b 0} {$b < 5} {incr b} {
    pin "r:/WORK/$top/s2_replayMSHRId${gsuf}_reg\[$b\]" \
                          "i:/WORK/$top/u_core/s2_mshr_q_reg\[$i\]\[$b\]"
  }
}

# ---- perf 两级流水（13 项；index 3 是 1 位 replay_full，其余 2 位）----
for {set k 0} {$k < 13} {incr k} {
  set gs [expr {$k == 0 ? "" : ""}]
  if {$k == 3} {
    pin "r:/WORK/$top/io_perf_3_value_REG_reg"   "i:/WORK/$top/u_core/perfFull0_reg"
    pin "r:/WORK/$top/io_perf_3_value_REG_1_reg" "i:/WORK/$top/u_core/perfFull1_reg"
  } else {
    for {set b 0} {$b < 2} {incr b} {
      pin "r:/WORK/$top/io_perf_${k}_value_REG_reg\[$b\]" \
                            "i:/WORK/$top/u_core/perfReg0_reg\[$k\]\[$b\]"
      pin "r:/WORK/$top/io_perf_${k}_value_REG_1_reg\[$b\]" \
                            "i:/WORK/$top/u_core/perfReg1_reg\[$k\]\[$b\]"
    }
  }
}

puts "LQR_PIN_END LoadQueueReplay n=$::LQR_PIN_OK miss=$::LQR_PIN_BAD expect=$::LQR_PIN_EXPECT"
# fail-closed 两道，都在最后一次 set_user_match **之后**，且都用 `error` 不用 `exit`：
#   `exit` 在正式签核里走 `interp create -safe`，会抛 "invalid command name exit"
#   而宿主还活着（本地 make fm-X 走顶层 source 时才真退出）—— 两个上下文行为不同，
#   所以守卫只能用 error。
#   (1) 一条都不许被拒；
#   (2) 成功条数必须**恰好**等于期望数量（字面整数，钉死）。
#       6290 是分析式手算出来的：288 + 72 + 72 + 720 + 792 + 3600 + 504
#                              + 48 + 15 + 66 + 15 + 48 + 50 = 6290
#       （逐组明细见 docs/loadqueuereplay_fm_prereg.md；与桩执行计数两法一致）
if {$::LQR_PIN_BAD != 0} {
  error "LQR_PIN_MISS=LoadQueueReplay miss=$::LQR_PIN_BAD first=$::LQR_PIN_FIRSTBAD"
}
if {$::LQR_PIN_OK != 6290} {
  error "LQR_PIN_COUNT=LoadQueueReplay n=$::LQR_PIN_OK expect=$::LQR_PIN_EXPECT"
}
