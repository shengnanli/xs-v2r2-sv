# NewIFU FM 钉点(FM 审计 2026-07) —— 匹配前(FM_PIN_PRE_TCL)版本:
# post-match set_user_match 对「已被错配的点」不生效(签名先到先得), 必须在首次
# match 之前钉死。
# 1) 位下标错位族：impl 用非零基 range 声明 [VAddrBits-1:PcCutPoint]=[49:11]，
#    golden 对应 reg 是零基 [38:0]。FM 名字配对按「同下标」把 ref[11..38]↔impl[11..38]
#    直接配上（差 11 位错位），余位交叉签名配对——pc 高位族全 fail 且下游
#    (foldpc/pdWb pc/toIbuffer pc/黑盒 io_pc) 全被毒化。按 ref[b]↔impl[b+11] 钉死。
# 2) perf：golden io_perf_N_value_REG/REG_1 两拍延迟 ↔ impl perf_s1/s2[N]（RTL 已从
#    误写的饱和计数器改回两拍延迟）。
# 3) golden 重复副本/裸名 RegNext：REG(=f2_fire&~f2_flush)↔f2_fire_no_flush_q、
#    wb_enable_REG↔wb_enable_q、mmioFlushWb_valid_REG↔fromUncache_fire_r、
#    mmio_redirect_REG↔mmio_redirect_fire_r。
# 4) 后端 redirect 打拍族名字差：fromFtqRedirectReg_bits_r_* ↔ redirReg_*。
#    （上轮 f2_fire_no_flush_q 被签名分析错配到 ftqOffset[2]，先 undo。）
# 5) f3_mmio_data_0/1 ↔ mmio_hw0/hw1。
set _n 0; set _f 0
proc _pin {r i} {
  if {[catch {set_user_match $r $i} msg]} { puts "PIN_FAIL: $r <-> $i ($msg)"; incr ::_f } else { incr ::_n }
}

# 1) pc 高位族（39 位，ref[b] ↔ impl[b+11]）
foreach fam {f2_pc_high f2_pc_high_plus1 f3_pc_high f3_pc_high_plus1 wb_pc_high wb_pc_high_plus1} {
  for {set b 0} {$b < 39} {incr b} {
    _pin "r:/WORK/$top/${fam}_reg\[$b\]" "i:/WORK/$top/u_core/${fam}_reg\[[expr {$b+11}]\]"
  }
}

# 2) perf 两拍
for {set k 0} {$k < 13} {incr k} {
  _pin "r:/WORK/$top/io_perf_${k}_value_REG_reg"   "i:/WORK/$top/u_core/perf_s1_reg\[$k\]"
  _pin "r:/WORK/$top/io_perf_${k}_value_REG_1_reg" "i:/WORK/$top/u_core/perf_s2_reg\[$k\]"
}

# 3) 裸名 RegNext / 重复副本
_pin "r:/WORK/$top/REG_reg"                  "i:/WORK/$top/u_core/f2_fire_no_flush_q_reg"
_pin "r:/WORK/$top/wb_enable_REG_reg"        "i:/WORK/$top/u_core/wb_enable_q_reg"
_pin "r:/WORK/$top/mmioFlushWb_valid_REG_reg" "i:/WORK/$top/u_core/fromUncache_fire_r_reg"
_pin "r:/WORK/$top/mmio_redirect_REG_reg"    "i:/WORK/$top/u_core/mmio_redirect_fire_r_reg"

# 4) redirect 打拍族
_pin "r:/WORK/$top/fromFtqRedirectReg_valid_REG_reg"    "i:/WORK/$top/u_core/fromFtqRedirectReg_valid_reg"
_pin "r:/WORK/$top/fromFtqRedirectReg_bits_r_ftqIdx_flag_reg" "i:/WORK/$top/u_core/redirReg_ftqIdx_flag_reg"
_pin "r:/WORK/$top/fromFtqRedirectReg_bits_r_level_reg" "i:/WORK/$top/u_core/redirReg_level_reg"
for {set b 0} {$b < 6} {incr b} {
  _pin "r:/WORK/$top/fromFtqRedirectReg_bits_r_ftqIdx_value_reg\[$b\]" "i:/WORK/$top/u_core/redirReg_ftqIdx_value_reg\[$b\]"
}
# wb 级 ftqIdx（impl 已裁成独立两寄存器 wb_ftqIdx_flag/value）
_pin "r:/WORK/$top/wb_ftq_req_ftqIdx_flag_reg" "i:/WORK/$top/u_core/wb_ftqIdx_flag_reg"
for {set b 0} {$b < 6} {incr b} {
  _pin "r:/WORK/$top/wb_ftq_req_ftqIdx_value_reg\[$b\]" "i:/WORK/$top/u_core/wb_ftqIdx_value_reg\[$b\]"
}
for {set b 0} {$b < 4} {incr b} {
  _pin "r:/WORK/$top/fromFtqRedirectReg_bits_r_ftqOffset_reg\[$b\]" "i:/WORK/$top/u_core/redirReg_ftqOffset_reg\[$b\]"
}

# 5) mmio 半字数据
for {set b 0} {$b < 16} {incr b} {
  _pin "r:/WORK/$top/f3_mmio_data_0_reg\[$b\]" "i:/WORK/$top/u_core/mmio_hw0_reg\[$b\]"
  _pin "r:/WORK/$top/f3_mmio_data_1_reg\[$b\]" "i:/WORK/$top/u_core/mmio_hw1_reg\[$b\]"
}

# 6) wb 级 false_lastHalf 原始位(golden wb_false_lastHalf_r ↔ impl wb_false_lastHalf_raw)
_pin "r:/WORK/$top/wb_false_lastHalf_r_reg" "i:/WORK/$top/u_core/wb_false_lastHalf_raw_reg"
# 7) wb 级 checker fixedTaken 打拍(名字差: check_result_stage1_fixedTaken_N ↔ wb_chk_fixedTaken[N])
for {set n 0} {$n < 16} {incr n} {
  _pin "r:/WORK/$top/wb_check_result_stage1_fixedTaken_${n}_reg" "i:/WORK/$top/u_core/wb_chk_fixedTaken_reg\[$n\]"
}
# 8) F3Predecoder 黑盒输出脚: 实例路径不同(golden f3Predecoder ↔ impl u_f3pd/u),
#    topology 配对把部分 brType/isRet 交叉配错, 逐脚钉死。
for {set n 0} {$n < 16} {incr n} {
  foreach f {isCall isRet} {
    _pin "r:/WORK/$top/f3Predecoder/io_out_pd_${n}_${f}" "i:/WORK/$top/u_core/u_f3pd/u/io_out_pd_${n}_${f}"
  }
  for {set b 0} {$b < 2} {incr b} {
    _pin "r:/WORK/$top/f3Predecoder/io_out_pd_${n}_brType\[$b\]" "i:/WORK/$top/u_core/u_f3pd/u/io_out_pd_${n}_brType\[$b\]"
  }
}

# 9) lastHalf 三副本 + f3_fire 打拍（golden REG_1/REG_2/REG_3）
_pin "r:/WORK/$top/REG_1_reg" "i:/WORK/$top/u_core/f3_hasLastHalf_q_reg"
_pin "r:/WORK/$top/REG_2_reg" "i:/WORK/$top/u_core/f3_fire_q_reg"
_pin "r:/WORK/$top/REG_3_reg" "i:/WORK/$top/u_core/f3_hasLastHalf_q2_reg"

puts "NEWIFU_PRE_PINS: $_n pinned, $_f failed"
