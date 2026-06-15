MODULE = Frontend

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核（含 package xs_frontend_pkg + xs_Frontend_core）
RTL_SRCS     = $(RTL_DIR)/frontend/Frontend.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/Frontend_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# ----------------------------------------------------------------------------
# golden Frontend 例化的 25 个子模块及其全部传递依赖（自动算出，共 197 文件）。
# UT 双例化时 golden Frontend 与 Frontend_xs（同 body + 影子核）共用这一批 golden 实现，
# 故比对仅检验顶层 glue（打拍流水 + PC 连续性检查器）等价；子模块本身已各自验证过。
# ----------------------------------------------------------------------------
SUBMODS = \
  $(GOLDEN_RTL)/Arbiter1_InsUncacheResp.sv \
  $(GOLDEN_RTL)/Arbiter2_ICacheMissReq.sv \
  $(GOLDEN_RTL)/Arbiter5_MSHRAcquire.sv \
  $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/Composer.sv \
  $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv \
  $(GOLDEN_RTL)/DataModule__16entry.sv \
  $(GOLDEN_RTL)/DataModule__16entry_4.sv \
  $(GOLDEN_RTL)/DataModule__16entry_8.sv \
  $(GOLDEN_RTL)/DeMultiplexer.sv \
  $(GOLDEN_RTL)/DeMultiplexer_1.sv \
  $(GOLDEN_RTL)/DelayN.sv \
  $(GOLDEN_RTL)/DelayNWithValid.sv \
  $(GOLDEN_RTL)/DelayNWithValid_1.sv \
  $(GOLDEN_RTL)/DelayN_1.sv \
  $(GOLDEN_RTL)/DelayN_13.sv \
  $(GOLDEN_RTL)/DelayN_7.sv \
  $(GOLDEN_RTL)/DelayN_8.sv \
  $(GOLDEN_RTL)/DelayN_9.sv \
  $(GOLDEN_RTL)/F3Predecoder.sv \
  $(GOLDEN_RTL)/FIFOReg.sv \
  $(GOLDEN_RTL)/FTB.sv \
  $(GOLDEN_RTL)/FTBBank.sv \
  $(GOLDEN_RTL)/FTBEntryGen.sv \
  $(GOLDEN_RTL)/FauFTB.sv \
  $(GOLDEN_RTL)/FauFTBWay.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_21.sv \
  $(GOLDEN_RTL)/FoldedSRAMTemplate_23.sv \
  $(GOLDEN_RTL)/FrontendTrigger.sv \
  $(GOLDEN_RTL)/Ftq.sv \
  $(GOLDEN_RTL)/FtqNRSRAM.sv \
  $(GOLDEN_RTL)/FtqPcMemWrapper.sv \
  $(GOLDEN_RTL)/HPerfCounter.sv \
  $(GOLDEN_RTL)/HPerfMonitor.sv \
  $(GOLDEN_RTL)/IBuffer.sv \
  $(GOLDEN_RTL)/ICache.sv \
  $(GOLDEN_RTL)/ICacheCtrlUnit.sv \
  $(GOLDEN_RTL)/ICacheDataArray.sv \
  $(GOLDEN_RTL)/ICacheMSHR.sv \
  $(GOLDEN_RTL)/ICacheMSHR_1.sv \
  $(GOLDEN_RTL)/ICacheMSHR_10.sv \
  $(GOLDEN_RTL)/ICacheMSHR_11.sv \
  $(GOLDEN_RTL)/ICacheMSHR_12.sv \
  $(GOLDEN_RTL)/ICacheMSHR_13.sv \
  $(GOLDEN_RTL)/ICacheMSHR_2.sv \
  $(GOLDEN_RTL)/ICacheMSHR_3.sv \
  $(GOLDEN_RTL)/ICacheMSHR_4.sv \
  $(GOLDEN_RTL)/ICacheMSHR_5.sv \
  $(GOLDEN_RTL)/ICacheMSHR_6.sv \
  $(GOLDEN_RTL)/ICacheMSHR_7.sv \
  $(GOLDEN_RTL)/ICacheMSHR_8.sv \
  $(GOLDEN_RTL)/ICacheMSHR_9.sv \
  $(GOLDEN_RTL)/ICacheMainPipe.sv \
  $(GOLDEN_RTL)/ICacheMetaArray.sv \
  $(GOLDEN_RTL)/ICacheMissUnit.sv \
  $(GOLDEN_RTL)/ICacheReplacer.sv \
  $(GOLDEN_RTL)/IPrefetchPipe.sv \
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
  $(GOLDEN_RTL)/InstrMMIOEntry.sv \
  $(GOLDEN_RTL)/InstrUncache.sv \
  $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv \
  $(GOLDEN_RTL)/MbistClockGateCell.sv \
  $(GOLDEN_RTL)/MbistIntfFrontend.sv \
  $(GOLDEN_RTL)/MbistPipeFrontend.sv \
  $(GOLDEN_RTL)/MbistPipeFtb.sv \
  $(GOLDEN_RTL)/MbistPipeFtq.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay0.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay1.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay2.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay3.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheTag.sv \
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
  $(GOLDEN_RTL)/MuxBundle.sv \
  $(GOLDEN_RTL)/NewIFU.sv \
  $(GOLDEN_RTL)/PFEvent.sv \
  $(GOLDEN_RTL)/PMP.sv \
  $(GOLDEN_RTL)/PMPChecker.sv \
  $(GOLDEN_RTL)/PTWFilter.sv \
  $(GOLDEN_RTL)/PTWRepeaterNB.sv \
  $(GOLDEN_RTL)/PreDecode.sv \
  $(GOLDEN_RTL)/PredChecker.sv \
  $(GOLDEN_RTL)/Predictor.sv \
  $(GOLDEN_RTL)/PriorityMuxModule.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_16.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_20.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
  $(GOLDEN_RTL)/PriorityMuxModule_8.sv \
  $(GOLDEN_RTL)/Queue1_RegMapperInput_3.sv \
  $(GOLDEN_RTL)/RAS.sv \
  $(GOLDEN_RTL)/RASStack.sv \
  $(GOLDEN_RTL)/RVCExpander.sv \
  $(GOLDEN_RTL)/RegionWays.sv \
  $(GOLDEN_RTL)/SCTable.sv \
  $(GOLDEN_RTL)/SCTable_1.sv \
  $(GOLDEN_RTL)/SCTable_2.sv \
  $(GOLDEN_RTL)/SCTable_3.sv \
  $(GOLDEN_RTL)/SRAMTemplate.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_12.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_28.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_4.sv \
  $(GOLDEN_RTL)/SRAMTemplate_16.sv \
  $(GOLDEN_RTL)/SRAMTemplate_2.sv \
  $(GOLDEN_RTL)/SRAMTemplate_32.sv \
  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
  $(GOLDEN_RTL)/SRAMTemplate_4.sv \
  $(GOLDEN_RTL)/SRAMTemplate_44.sv \
  $(GOLDEN_RTL)/SRAMTemplate_45.sv \
  $(GOLDEN_RTL)/SRAMTemplate_64.sv \
  $(GOLDEN_RTL)/SRAMTemplate_66.sv \
  $(GOLDEN_RTL)/SRAMTemplate_70.sv \
  $(GOLDEN_RTL)/SRAMTemplate_72.sv \
  $(GOLDEN_RTL)/SRAMTemplate_78.sv \
  $(GOLDEN_RTL)/SRAMTemplate_8.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_24.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_26.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_29.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv \
  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv \
  $(GOLDEN_RTL)/TLB.sv \
  $(GOLDEN_RTL)/TLBFA.sv \
  $(GOLDEN_RTL)/TageBTable.sv \
  $(GOLDEN_RTL)/TageTable.sv \
  $(GOLDEN_RTL)/TageTable_1.sv \
  $(GOLDEN_RTL)/TageTable_2.sv \
  $(GOLDEN_RTL)/TageTable_3.sv \
  $(GOLDEN_RTL)/Tage_SC.sv \
  $(GOLDEN_RTL)/TlbStorageWrapper.sv \
  $(GOLDEN_RTL)/WayLookup.sv \
  $(GOLDEN_RTL)/WrBypass.sv \
  $(GOLDEN_RTL)/WrBypass_32.sv \
  $(GOLDEN_RTL)/WrBypass_33.sv \
  $(GOLDEN_RTL)/WrBypass_41.sv \
  $(GOLDEN_RTL)/WrBypass_43.sv \
  $(GOLDEN_RTL)/array.sv \
  $(GOLDEN_RTL)/array_0.sv \
  $(GOLDEN_RTL)/array_0_ext.v \
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
  $(GOLDEN_RTL)/array_7.sv \
  $(GOLDEN_RTL)/array_7_ext.v \
  $(GOLDEN_RTL)/array_ext.v \
  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
  $(GOLDEN_RTL)/data_mem_0_8x3.sv \
  $(GOLDEN_RTL)/data_mem_16x12.sv \
  $(GOLDEN_RTL)/data_mem_8x4.sv \
  $(GOLDEN_RTL)/perfEventsModule.sv \
  $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
  $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
  $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
  $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv \
  $(GOLDEN_RTL)/sram_array_2p64x144m144s1h0l1b_ftq.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Frontend.sv $(SUBMODS)

# FM ref 侧依赖留空：所有子模块两侧均不读源 → hdlin_unresolved_modules=black_box 统一黑盒，
# 顶层 glue + 子模块互联按签名比对等价（wrapper = golden body 忠实复制 + 悬空校验伴随）。
FM_VARIANTS = Frontend
FM_REF_DEPS_Frontend =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
