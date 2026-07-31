# BankedDataArray FM 钉点(FM 审计 2026-07 / codex_0093 §1 exact-cutpoint 2026-07-30)
# 无 dont_verify / 无 waiver / 无 relaxed appvar / 无 constant / 无 tie-off / 无 set_direction.
#
# 历史(已废弃): 之前把 DataSRAMBank*×8 + mbistPl 整体当 9 个对称黑盒时, golden 侧
# childBd_N_rdata(DataSRAMBank 的 boreChildrenBd_bore_*_rdata 输出, 本 config 为悬空死网)
# 被 FM 因 blackbox-pin direction-unknown 推成黑盒**输入**引脚(formality.log:
# "Direction of black-box pin ... is unknown; setting to in"), 其 fan-in = undriven
# cut-point → 20 个 data_banks_0_[0-7]/boreChildrenBd_bore_1_rdata[{0,10,11}] BBPin 比对点
# 因 ref-undriven(BINARY:X 默认下 ref=自由变量/impl=X)失配. 唯一掩盖手段是全局
# verification_set_undriven_signals=BINARY, 但它是全目标语义放宽(sidecar 判 relaxed_appvars
# → PARTIAL), codex_0093 §1 明令拒绝.
#
# 实证(2026-07-30, /tmp/bda-cutpoint-evidence): 4 种 per-point 精确手段均**无效**——
#   set_user_match(悬空死网 ref↔impl 双射)、set_constant(死网 0)、set_constant(BBPin 0)、
#   set_direction(BBPin out) 全部仍留 20 failing(FM 对 matched-BBPin-with-undriven-ref-fanin
#   的比对点无 per-point 割点表达). 故 Formality 无法用 set_user_match/cutpoint 精确配对这些
#   undriven bbox 引脚.
#
# 正解(功能保持的边界建模, 同 Slice codex_0036): 把 DataSRAMBank + SRAMTemplate 两侧同源
# elaborate(见 Makefile ELAB_SRCS / WRAPPER_SRCS / FM_REF_DEPS_BankedDataArray). 此时
# boreChildrenBd_bore_*_rdata 成 SRAM 真实驱动输出, undriven 死锥消失, 无需任何放宽 appvar.
# 唯一黑盒边界 = 厂商 SRAM 宏 array_8_ext + MBIST 管道 mbistPl(MbistPipeDCacheData).
# 实证 native: 0 unmatched compare / 0 unmatched bbox-out / 3(0) unread_ref(REG_8/9/10 dead_ref)
# / 0 failing / relaxed_appvars=[] 全空.
puts "BDA_PINS: no relax; DataSRAMBank/SRAMTemplate two-sided elaborated -> rdata driven (no undriven cone)"
