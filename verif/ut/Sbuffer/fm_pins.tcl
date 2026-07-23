# Sbuffer FM 钉点（FM 审计 2026-07 / 修复 2026-07-17 / signoff 2026-07-23）
# 1) 名称体系差异的批量 1:1 钉点：
#    * golden SbufferData 为子模块层次 dataModule/<name>_<idx>；impl 平铺在 u_core 数组。
#    * golden 顶层 forward 逻辑每 load 口一套展平标量（端口后缀 _1/_2 或前缀）；impl 为
#      generate g_fwd[pt] 作用域内数组。auto_match 的键规约对不上，逐点显式钉。
#    * 索引序均已对照 golden 源码核实（line/word/byte、port 后缀、REG 连续编号）。
# 2) 不再放宽 verification_assume_reg_init / verification_set_undriven_signals：
#    经证 26797 compare points 在 FM 默认 appvar(auto / BINARY:X) 下同样 0 failing/0
#    unread，去掉这两个 OPTIONAL relaxing appvar 消 assembly_qualifications(PARTIAL)。
setup

set _n 0
proc _pin {r i} {
  if {![catch {set_user_match $r $i}]} { incr ::_n }
}

# ---- dataModule: cacheline data/mask（16 line × 4 word × 16 byte）----
for {set l 0} {$l < 16} {incr l} {
  for {set w 0} {$w < 4} {incr w} {
    for {set b 0} {$b < 16} {incr b} {
      for {set k 0} {$k < 8} {incr k} {
        _pin "r:/WORK/$top/dataModule/data_${l}_${w}_${b}_reg\[$k\]" \
             "i:/WORK/$top/u_core/cline_data_reg\[$l\]\[$w\]\[$b\]\[$k\]"
      }
      _pin "r:/WORK/$top/dataModule/mask_${l}_${w}_${b}_reg" \
           "i:/WORK/$top/u_core/cline_mask_reg\[$l\]\[$w\]\[$b\]"
    }
  }
}

# ---- dataModule: line write buffer（port p: p0 无后缀 / p1 后缀 _1；line l）----
for {set p 0} {$p < 2} {incr p} {
  set ps [expr {$p == 0 ? "" : "_1"}]
  for {set l 0} {$l < 16} {incr l} {
    for {set k 0} {$k < 128} {incr k} {
      _pin "r:/WORK/$top/dataModule/line_write_buffer_data_${l}${ps}_reg\[$k\]" \
           "i:/WORK/$top/u_core/s2_data_reg\[$p\]\[$l\]\[$k\]"
    }
    for {set k 0} {$k < 16} {incr k} {
      _pin "r:/WORK/$top/dataModule/line_write_buffer_mask_${l}${ps}_reg\[$k\]" \
           "i:/WORK/$top/u_core/s2_mask_reg\[$p\]\[$l\]\[$k\]"
    }
    for {set k 0} {$k < 2} {incr k} {
      _pin "r:/WORK/$top/dataModule/line_write_buffer_offset_${l}${ps}_reg\[$k\]" \
           "i:/WORK/$top/u_core/s2_offset_reg\[$p\]\[$l\]\[$k\]"
    }
    _pin "r:/WORK/$top/dataModule/line_write_buffer_wline_${l}${ps}_reg" \
         "i:/WORK/$top/u_core/s2_wline_reg\[$p\]\[$l\]"
    # line_wen 打拍：REG_{p*16+l} 连续编号（n=0 无后缀）
    set n [expr {$p * 16 + $l}]
    set ns [expr {$n == 0 ? "" : "_$n"}]
    _pin "r:/WORK/$top/dataModule/sbuffer_in_s2_line_wen_last_REG${ns}_reg" \
         "i:/WORK/$top/u_core/s2_line_wen_reg\[$p\]\[$l\]"
  }
}

# ---- dataModule: line mask clean 打拍（REG_l，l=0 无后缀）----
for {set l 0} {$l < 16} {incr l} {
  set ls [expr {$l == 0 ? "" : "_$l"}]
  _pin "r:/WORK/$top/dataModule/line_mask_clean_flag_last_REG${ls}_reg" \
       "i:/WORK/$top/u_core/line_mask_clean_q_reg\[$l\]"
}

# ---- forward（3 个 load 口 pt=0/1/2）----
for {set pt 0} {$pt < 3} {incr pt} {
  # 端口后缀（valid/inflight_tag_match_reg_<w>{,_1,_2}）与前缀（candidate: reg{,_1,_2}_l_b）
  set sfx [expr {$pt == 0 ? "" : "_$pt"}]
  # tag_mismatch_last_REG 连续编号: pt*33 + {0=valid, 2w+1=vtag副本, 2w+2=act|infl副本}
  set base [expr {$pt * 33}]
  set bs [expr {$base == 0 ? "" : "_$base"}]
  _pin "r:/WORK/$top/tag_mismatch_last_REG${bs}_reg" \
       "i:/WORK/$top/u_core/g_fwd\[$pt\].fwd_valid_q_reg"
  for {set w 0} {$w < 16} {incr w} {
    _pin "r:/WORK/$top/tag_mismatch_last_REG_[expr {$base + 2*$w + 1}]_reg" \
         "i:/WORK/$top/u_core/g_fwd\[$pt\].vtag_match_q_reg\[$w\]"
    _pin "r:/WORK/$top/tag_mismatch_last_REG_[expr {$base + 2*$w + 2}]_reg" \
         "i:/WORK/$top/u_core/g_fwd\[$pt\].act_or_infl_q_reg\[$w\]"
    _pin "r:/WORK/$top/valid_tag_match_reg_${w}${sfx}_reg" \
         "i:/WORK/$top/u_core/g_fwd\[$pt\].valid_tag_match_q_reg\[$w\]"
    _pin "r:/WORK/$top/inflight_tag_match_reg_${w}${sfx}_reg" \
         "i:/WORK/$top/u_core/g_fwd\[$pt\].inflight_tag_match_q_reg\[$w\]"
    # ptag_matches_r 连续编号: pt*32 + {2w=entry ptag 副本, 2w+1=fwd ptag 副本}
    set pn [expr {$pt * 32 + 2 * $w}]
    set pns [expr {$pn == 0 ? "" : "_$pn"}]
    for {set k 0} {$k < 42} {incr k} {
      _pin "r:/WORK/$top/ptag_matches_r${pns}_reg\[$k\]" \
           "i:/WORK/$top/u_core/g_fwd\[$pt\].ptag_q_reg\[$w\]\[$k\]"
      # fwd ptag 的 16 份重复副本（merge_dup 折叠后仅存 1 份，其余 catch 吞掉）
      _pin "r:/WORK/$top/ptag_matches_r_[expr {$pn + 1}]_reg\[$k\]" \
           "i:/WORK/$top/u_core/g_fwd\[$pt\].fwd_ptag_q_reg\[$k\]"
    }
  }
  # 候选 data/mask：forward_{data,mask}_candidate_reg{,_1,_2}_<line>_<byte>
  for {set l 0} {$l < 16} {incr l} {
    for {set b 0} {$b < 16} {incr b} {
      for {set k 0} {$k < 8} {incr k} {
        _pin "r:/WORK/$top/forward_data_candidate_reg${sfx}_${l}_${b}_reg\[$k\]" \
             "i:/WORK/$top/u_core/g_fwd\[$pt\].data_cand_q_reg\[$l\]\[$b\]\[$k\]"
      }
      _pin "r:/WORK/$top/forward_mask_candidate_reg${sfx}_${l}_${b}_reg" \
           "i:/WORK/$top/u_core/g_fwd\[$pt\].mask_cand_q_reg\[$l\]\[$b\]"
    }
  }
}

# ---- PLRU state / accessIdx / hit_resp id 副本 / RegNext(hit_resp) 副本 ----
for {set k 0} {$k < 15} {incr k} {
  _pin "r:/WORK/$top/state_reg_reg\[$k\]" "i:/WORK/$top/u_core/plru_state_reg\[$k\]"
}
_pin "r:/WORK/$top/accessIdx_0_valid_REG_reg" "i:/WORK/$top/u_core/accessIdx0_valid_q_reg"
_pin "r:/WORK/$top/accessIdx_1_valid_REG_reg" "i:/WORK/$top/u_core/accessIdx1_valid_q_reg"
for {set k 0} {$k < 4} {incr k} {
  _pin "r:/WORK/$top/accessIdx_0_bits_r_reg\[$k\]" "i:/WORK/$top/u_core/accessIdx0_idx_q_reg\[$k\]"
  _pin "r:/WORK/$top/accessIdx_1_bits_r_reg\[$k\]" "i:/WORK/$top/u_core/accessIdx1_idx_q_reg\[$k\]"
}
# hit_resp id 的 16 份副本 r/r_1..r_15（merge_dup 折叠后仅存 1 份）
for {set n 0} {$n < 16} {incr n} {
  set ns [expr {$n == 0 ? "" : "_$n"}]
  for {set k 0} {$k < 4} {incr k} {
    _pin "r:/WORK/$top/r${ns}_reg\[$k\]" "i:/WORK/$top/u_core/hit_resp_id_q_reg\[$k\]"
  }
  _pin "r:/WORK/$top/last_REG${ns}_reg" "i:/WORK/$top/u_core/hit_resp_fire_q_reg"
}

# ---- missqReplay / drain / perf 打拍链 ----
_pin "r:/WORK/$top/missqReplayHasTimeOut_last_REG_reg"   "i:/WORK/$top/u_core/missqReplayHasTimeOut_q_reg"
_pin "r:/WORK/$top/missqReplayHasTimeOut_last_REG_1_reg" "i:/WORK/$top/u_core/out_s0_fire_q_reg"
_pin "r:/WORK/$top/do_uarch_drain_last_REG_reg"   "i:/WORK/$top/u_core/fwd_drain_q_reg"
_pin "r:/WORK/$top/do_uarch_drain_last_REG_1_reg" "i:/WORK/$top/u_core/merge_drain_q_reg"
_pin "r:/WORK/$top/do_uarch_drain_last_REG_2_reg" "i:/WORK/$top/u_core/merge_drain_q2_reg"
for {set n 0} {$n < 16} {incr n} {
  # perf0..3 为 2 位，其余 1 位；两种形态都试（catch 吞不存在的）
  for {set k 0} {$k < 2} {incr k} {
    _pin "r:/WORK/$top/io_perf_${n}_value_REG_reg\[$k\]"   "i:/WORK/$top/u_core/p${n}a_reg\[$k\]"
    _pin "r:/WORK/$top/io_perf_${n}_value_REG_1_reg\[$k\]" "i:/WORK/$top/u_core/p${n}b_reg\[$k\]"
  }
  _pin "r:/WORK/$top/io_perf_${n}_value_REG_reg"   "i:/WORK/$top/u_core/p${n}a_reg"
  _pin "r:/WORK/$top/io_perf_${n}_value_REG_1_reg" "i:/WORK/$top/u_core/p${n}b_reg"
}

puts "SBUF_PINS: applied ($_n pinned)"
