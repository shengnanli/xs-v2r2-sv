# Predictor UT/FM 入口 —— BPU 顶层流水与全局历史管理。
#
# Predictor 的子模块都**不是本目标**，两侧共用同一份 golden 定义，所以 UT 比的、
# FM 证的都只是 Predictor 这一层。依赖分两类，共 98 个文件：
#   · Composer 及其 5 个预测器闭包（与 verif/ut/Composer 同一份清单）+ DelayN；
#   · golden Predictor 自己例化的 6 种 PriorityMuxModule（270 个实例）。它们是纯组合
#     优先选择器(0 寄存器)，可读核把这套逻辑直接写成 ? : 优先级链，所以**只有 ref 侧**
#     用得到 —— impl 侧一个都不例化。
MODULE = Predictor

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/Predictor.sv
TB_SRCS  = tb.sv

# golden 顶层（被比对的 ref）
GOLDEN_SRCS = $(GOLDEN_RTL)/Predictor.sv

RTL_GOLDEN_DEPS = \
  $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/Composer.sv \
  $(GOLDEN_RTL)/DelayN.sv \
  $(GOLDEN_RTL)/DelayNWithValid.sv \
  $(GOLDEN_RTL)/DelayNWithValid_1.sv \
  $(GOLDEN_RTL)/DelayN_1.sv \
  $(GOLDEN_RTL)/FTB.sv \
  $(GOLDEN_RTL)/FTBBank.sv \
  $(GOLDEN_RTL)/FauFTB.sv \
  $(GOLDEN_RTL)/FauFTBWay.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_22.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_24.sv \
  $(GOLDEN_RTL)/ITTage.sv \
  $(GOLDEN_RTL)/ITTageTable.sv \
  $(GOLDEN_RTL)/ITTageTable_1.sv \
  $(GOLDEN_RTL)/ITTageTable_2.sv \
  $(GOLDEN_RTL)/ITTageTable_3.sv \
  $(GOLDEN_RTL)/ITTageTable_4.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv \
  $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
  $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv \
  $(GOLDEN_RTL)/MbistClockGateCell.sv \
  $(GOLDEN_RTL)/MbistPipeFtb.sv \
  $(GOLDEN_RTL)/MbistPipeIttage.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_1.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_2.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_3.sv \
  $(GOLDEN_RTL)/MbistPipeIttage_4.sv \
  $(GOLDEN_RTL)/MbistPipeSc.sv \
  $(GOLDEN_RTL)/MbistPipeSc_1.sv \
  $(GOLDEN_RTL)/MbistPipeSc_2.sv \
  $(GOLDEN_RTL)/MbistPipeSc_3.sv \
  $(GOLDEN_RTL)/MbistPipeTage.sv \
  $(GOLDEN_RTL)/PriorityMuxModule.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_16.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_20.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_8.sv \
  $(GOLDEN_RTL)/RAS.sv \
  $(GOLDEN_RTL)/RASStack.sv \
  $(GOLDEN_RTL)/RegionWays.sv \
  $(GOLDEN_RTL)/SCTable.sv \
  $(GOLDEN_RTL)/SCTable_1.sv \
  $(GOLDEN_RTL)/SCTable_2.sv \
  $(GOLDEN_RTL)/SCTable_3.sv \
  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
  $(GOLDEN_RTL)/SRAMTemplate_44.sv \
  $(GOLDEN_RTL)/SRAMTemplate_45.sv \
  $(GOLDEN_RTL)/SRAMTemplate_64.sv \
  $(GOLDEN_RTL)/SRAMTemplate_68.sv \
  $(GOLDEN_RTL)/SRAMTemplate_76.sv \
  $(GOLDEN_RTL)/SRAMTemplate_78.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
  $(GOLDEN_RTL)/TageBTable.sv \
  $(GOLDEN_RTL)/TageTable.sv \
  $(GOLDEN_RTL)/TageTable_1.sv \
  $(GOLDEN_RTL)/TageTable_2.sv \
  $(GOLDEN_RTL)/TageTable_3.sv \
  $(GOLDEN_RTL)/Tage_SC.sv \
  $(GOLDEN_RTL)/WrBypass.sv \
  $(GOLDEN_RTL)/WrBypass_32.sv \
  $(GOLDEN_RTL)/WrBypass_33.sv \
  $(GOLDEN_RTL)/WrBypass_41.sv \
  $(GOLDEN_RTL)/WrBypass_43.sv \
  $(GOLDEN_RTL)/array_1.sv \
  $(GOLDEN_RTL)/array_1_ext.v \
  $(GOLDEN_RTL)/array_2.sv \
  $(GOLDEN_RTL)/array_2_ext.v \
  $(GOLDEN_RTL)/array_3.sv \
  $(GOLDEN_RTL)/array_3_ext.v \
  $(GOLDEN_RTL)/array_4.sv \
  $(GOLDEN_RTL)/array_4_ext.v \
  $(GOLDEN_RTL)/array_5.sv \
  $(GOLDEN_RTL)/array_5_ext.v \
  $(GOLDEN_RTL)/array_6.sv \
  $(GOLDEN_RTL)/array_6_ext.v \
  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
  $(GOLDEN_RTL)/data_mem_0_8x3.sv \
  $(GOLDEN_RTL)/data_mem_16x12.sv \
  $(GOLDEN_RTL)/data_mem_8x4.sv \
  $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

FM_VARIANTS = Predictor
FM_REF_DEPS_Predictor = ClockGate.sv Composer.sv DelayN.sv DelayNWithValid.sv \
  DelayNWithValid_1.sv DelayN_1.sv FTB.sv FTBBank.sv \
  FauFTB.sv FauFTBWay.sv FoldedSRAMTemplate.sv FoldedSRAMTemplate_1.sv \
  FoldedSRAMTemplate_20.sv FoldedSRAMTemplate_22.sv FoldedSRAMTemplate_24.sv ITTage.sv \
  ITTageTable.sv ITTageTable_1.sv ITTageTable_2.sv ITTageTable_3.sv \
  ITTageTable_4.sv IndexableCAMTemplate.sv IndexableCAMTemplate_32.sv IndexableCAMTemplate_33.sv \
  IndexableCAMTemplate_41.sv IndexableCAMTemplate_43.sv MaxPeriodFibonacciLFSR.sv MbistClockGateCell.sv \
  MbistPipeFtb.sv MbistPipeIttage.sv MbistPipeIttage_1.sv MbistPipeIttage_2.sv \
  MbistPipeIttage_3.sv MbistPipeIttage_4.sv MbistPipeSc.sv MbistPipeSc_1.sv \
  MbistPipeSc_2.sv MbistPipeSc_3.sv MbistPipeTage.sv PriorityMuxModule.sv \
  PriorityMuxModule_12.sv PriorityMuxModule_16.sv PriorityMuxModule_20.sv PriorityMuxModule_4.sv \
  PriorityMuxModule_8.sv RAS.sv RASStack.sv RegionWays.sv \
  SCTable.sv SCTable_1.sv SCTable_2.sv SCTable_3.sv \
  SRAMTemplate_36.sv SRAMTemplate_44.sv SRAMTemplate_45.sv SRAMTemplate_64.sv \
  SRAMTemplate_68.sv SRAMTemplate_76.sv SRAMTemplate_78.sv SplittedSRAMTemplate_2.sv \
  SplittedSRAMTemplate_23.sv SplittedSRAMTemplate_25.sv SplittedSRAMTemplate_27.sv SplittedSRAMTemplate_3.sv \
  SplittedSRAMTemplate_4.sv TageBTable.sv TageTable.sv TageTable_1.sv \
  TageTable_2.sv TageTable_3.sv Tage_SC.sv WrBypass.sv \
  WrBypass_32.sv WrBypass_33.sv WrBypass_41.sv WrBypass_43.sv \
  array_1.sv array_1_ext.v array_2.sv array_2_ext.v \
  array_3.sv array_3_ext.v array_4.sv array_4_ext.v \
  array_5.sv array_5_ext.v array_6.sv array_6_ext.v \
  data_mem_0_4x2.sv data_mem_0_8x3.sv data_mem_16x12.sv data_mem_8x4.sv \
  sram_array_1p128x24m6s1h0l1b_bp_sc.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
  sram_array_1p512x24m12s1h0l1b_bp_tage.sv sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2
VCS += +define+SYNTHESIS
