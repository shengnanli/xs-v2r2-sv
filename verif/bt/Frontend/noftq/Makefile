MODULE = Frontend_BT_noftq

RTL_DIR    = ../../../../rtl
GOLDEN_RTL = ../../../../golden/chisel-rtl
UT_DIR     = ../../../ut
IT_DIR     = ../../../it

# ===========================================================================
# BT（块级，整 Frontend 子系统）：golden Frontend (u_g) vs 全重写 Frontend_bt (u_i)
#
#   Frontend_bt：顶层端口 = golden Frontend；内部把五大子模块实例换成重写装配
#   （端口逐字相同，按名直连），顶层 glue 用重写 xs_Frontend_core 在环观察：
#       Predictor inner_bpu     -> Predictor_it  （IT 全重写 BPU 簇）
#       NewIFU    inner_ifu      -> NewIFU_it     （IT 全重写 IFU 簇）
#       ICache    inner_icache   -> ICache_xs     （重写 xs_ICache_core glue）
#       Ftq       inner_ftq      -> Ftq_xs        （重写 xs_Ftq_core glue）
#       IBuffer   inner_ibuffer  -> IBuffer_xs    （重写 xs_IBuffer_core glue）
#
#   叶子边界（golden 与 rewrite 两侧共用同一份，非算法原语）：
#     · SRAM 模板/宏、IndexableCAM、DataModule/SyncDataModule、FtqNRSRAM/FtqPcMem
#     · ICache MainPipe/MissUnit/MetaArray/DataArray/Prefetch/Replacer/MSHR
#     · BPU 叶子的 FTBBank / TageTable / SCTable / ITTageTable / RASStack 等存储件
#     · IFU 的 PredChecker / FrontendTrigger（工程无独立重写核，IT 即保留 golden）
#   外围 golden 基础设施（顶层互联 body 内，工程未提供等价重写核，如实保留）：
#     · InstrUncache（MMIO 取指）、TLB/PTWFilter/PTWRepeaterNB(ITLB)、PMP/PMPChecker
#     · PFEvent/HPerfMonitor、DelayN 打拍件、MbistPipe/Intf(DFT)
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：pkg + 重写算法叶子核 + 各 xs glue 核 + 适配器/IT 装配
# ---------------------------------------------------------------------------
# -- BPU 簇重写核（算法叶子全部在此） --
XS_BPU_CORES = \
    $(RTL_DIR)/frontend/ftb_pkg.sv \
    $(RTL_DIR)/frontend/FTB.sv \
    $(RTL_DIR)/frontend/FauFTBWay.sv \
    $(RTL_DIR)/frontend/FauFTB.sv \
    $(RTL_DIR)/frontend/Tage_SC.sv \
    $(RTL_DIR)/frontend/ITTage.sv \
    $(RTL_DIR)/frontend/RAS.sv \
    $(RTL_DIR)/frontend/Composer.sv \
    $(RTL_DIR)/frontend/Predictor.sv

# -- BPU 簇重写叶子适配器（golden 扁平端口 -> xs 核；复用各模块 UT 的 variants_xs.sv） --
XS_BPU_ADAPTERS = \
    $(UT_DIR)/FTB/variants_xs.sv \
    $(UT_DIR)/FauFTB/variants_xs.sv \
    $(UT_DIR)/Tage_SC/variants_xs.sv \
    $(UT_DIR)/ITTage/variants_xs.sv \
    $(UT_DIR)/RAS/variants_xs.sv

# -- BPU 簇 IT 装配（RAS_it / Composer_it / Predictor_it） --
IT_BPU_ASSEMBLY = \
    $(IT_DIR)/BPU/RAS_it.sv \
    $(IT_DIR)/BPU/Composer_it.sv \
    $(IT_DIR)/BPU/Predictor_it.sv

# -- IFU 簇重写：译码/展开包 + 重写算法叶子核 + xs_NewIFU_core glue --
XS_IFU = \
    $(RTL_DIR)/frontend/predecode_pkg.sv \
    $(RTL_DIR)/frontend/rvc_expander_pkg.sv \
    $(RTL_DIR)/frontend/PreDecode.sv \
    $(RTL_DIR)/frontend/F3Predecoder.sv \
    $(RTL_DIR)/frontend/RVCExpander.sv \
    $(RTL_DIR)/frontend/NewIFU.sv

# -- IFU 簇 IT 装配：重写叶子版子适配器 + 适配器壳 + IT 顶层 --
IT_IFU_ASSEMBLY = \
    $(IT_DIR)/IFU/NewIFU_subs_it.sv \
    $(UT_DIR)/NewIFU/variants_xs.sv \
    $(IT_DIR)/IFU/NewIFU_it.sv

# -- ICache / Ftq / IBuffer 重写 glue 核 + 各自 UT 适配器壳 --
XS_MEMPIPE_CORES = \
    $(RTL_DIR)/frontend/ICache.sv \
    $(RTL_DIR)/frontend/Ftq.sv \
    $(RTL_DIR)/frontend/IBuffer.sv

XS_MEMPIPE_ADAPTERS = \
    $(UT_DIR)/ICache/variants_xs.sv \
    $(UT_DIR)/Ftq/variants_xs.sv \
    $(UT_DIR)/IBuffer/variants_xs.sv

# -- 重写顶层 glue 核（xs_frontend_pkg + xs_Frontend_core） --
XS_FRONTEND_CORE = \
    $(RTL_DIR)/frontend/Frontend.sv

# -- BT 顶层装配（本目录） --
BT_ASSEMBLY = ../Frontend_bt_noftq.sv

# ---------------------------------------------------------------------------
# golden 闭包：golden Frontend 顶层 + 例化的 25 个子模块及其全部传递依赖
#   （与 verif/ut/Frontend/Makefile 的 SUBMODS 同一批，共 197 文件）。
#   既为 u_g（golden Frontend）提供 golden 子模块顶层（Predictor/NewIFU/ICache/Ftq/
#   IBuffer/InstrUncache/TLB/PMP/...），又提供 u_i 重写核共用的存储/算法叶子。
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = \
    $(XS_BPU_CORES) $(XS_BPU_ADAPTERS) $(IT_BPU_ASSEMBLY) \
    $(XS_IFU) $(IT_IFU_ASSEMBLY) \
    $(XS_MEMPIPE_CORES) $(XS_MEMPIPE_ADAPTERS) \
    $(XS_FRONTEND_CORE) \
    $(BT_ASSEMBLY)

GOLDEN_SRCS = $(GOLDEN_RTL)/Frontend.sv $(SUBMODS)

TB_SRCS = ../tb_noftq.sv

# BT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 随机初值/运行时断言；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
