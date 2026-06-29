MODULE = MemBlock_bt

RTL_DIR    = ../../../rtl
UT_DIR     = ../../ut
GOLDEN_RTL = ../../../golden/chisel-rtl

# ----------------------------------------------------------------------------
# BT(块级)装配:重写 MemBlock 互联 glue 核(xs_MemBlock_core_bt) + clean-swap-set 子模块
# 全用重写件直连(DCacheWrapper / Uncache / L2TLBWrapper / Sbuffer / TLBNonBlock-ld /
# PMP / PMPChecker_10 → 各自 xs_<M>_core),整子系统对比 golden MemBlock 逐拍比 1346 输出。
# 其余 ~60 子模块(向量访存 / LSU 流水 / LSQ / MemExeUnit / 预取器 / Atomics / PTW repeater /
# TLBNonBlock_1/_2 等)保留 golden——无重写核或非干净双例化(详见 README 覆盖范围)。
# ----------------------------------------------------------------------------
# 重写类型包 + 各重写核 + _xs 适配器 + _bt 全端口包装 + 顶层 BT 装配。
RTL_SRCS = \
  $(RTL_DIR)/memblock/memblock_pkg.sv \
  $(RTL_DIR)/memblock/uncache_pkg.sv \
  $(RTL_DIR)/memblock/sbuffer_pkg.sv \
  $(RTL_DIR)/memblock/tlbnonblock_pkg.sv \
  $(RTL_DIR)/memblock/tlbstoragewrapper_pkg.sv \
  $(RTL_DIR)/memblock/tlbfa_pkg.sv \
  $(RTL_DIR)/memblock/pmp_pkg.sv \
  $(RTL_DIR)/memblock/DCacheWrapper.sv \
  $(RTL_DIR)/memblock/Uncache.sv \
  $(RTL_DIR)/memblock/L2TLBWrapper.sv \
  $(RTL_DIR)/memblock/Sbuffer.sv \
  $(RTL_DIR)/memblock/TLBNonBlock.sv \
  $(RTL_DIR)/memblock/PMP.sv \
  $(RTL_DIR)/memblock/PMPChecker.sv \
  $(UT_DIR)/DCacheWrapper/variants_xs.sv \
  $(UT_DIR)/Uncache/variants_xs.sv \
  $(UT_DIR)/L2TLBWrapper/variants_xs.sv \
  $(UT_DIR)/Sbuffer/variants_xs.sv \
  $(UT_DIR)/TLBNonBlock/variants_xs.sv \
  $(UT_DIR)/PMP/variants_xs.sv \
  $(UT_DIR)/PMPChecker/variants_xs.sv \
  DCacheWrapper_bt.sv \
  Uncache_bt.sv \
  L2TLBWrapper_bt.sv \
  Sbuffer_bt.sv \
  TLBNonBlock_bt.sv \
  MemBlock_bt.sv \
  difftest_stub.sv

TB_SRCS = tb.sv

# golden MemBlock 例化访存子系统全部组件 —— 与 MemBlock UT 同一份 golden 闭包(273 文件)。
# u_g 用 golden 顶层 + 全部 golden 子模块; u_i(MemBlock_bt) 的未换子模块也复用这批 golden 定义。
GOLDEN_SRCS = $(GOLDEN_RTL)/MemBlock.sv \
$(GOLDEN_RTL)/AMOALU.sv $(GOLDEN_RTL)/ActiveGenerationTable.sv \
  $(GOLDEN_RTL)/AgeDetector_38.sv $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReq.sv \
  $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReqCtrl.sv $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter1_TagWriteReq.sv $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv $(GOLDEN_RTL)/Arbiter2_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv $(GOLDEN_RTL)/Arbiter2_PtwReq.sv \
  $(GOLDEN_RTL)/Arbiter2_StorePrefetchReq.sv $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv \
  $(GOLDEN_RTL)/Arbiter3_L2TlbMemReqBundle.sv $(GOLDEN_RTL)/Arbiter3_PfGenReq.sv \
  $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv \
  $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv $(GOLDEN_RTL)/AtomicsUnit.sv \
  $(GOLDEN_RTL)/BankedDataArray.sv $(GOLDEN_RTL)/BloomFilter.sv \
  $(GOLDEN_RTL)/CMOUnit.sv $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/CounterFilter.sv $(GOLDEN_RTL)/CtrlUnit.sv \
  $(GOLDEN_RTL)/DCache.sv $(GOLDEN_RTL)/DCacheWrapper.sv \
  $(GOLDEN_RTL)/DataSRAMBank.sv $(GOLDEN_RTL)/DataSRAMBank_1.sv \
  $(GOLDEN_RTL)/DataSRAMBank_2.sv $(GOLDEN_RTL)/DataSRAMBank_4.sv \
  $(GOLDEN_RTL)/DatamoduleResultBuffer.sv $(GOLDEN_RTL)/DelayNWithValid_103.sv \
  $(GOLDEN_RTL)/DelayNWithValid_148.sv $(GOLDEN_RTL)/DelayNWithValid_149.sv \
  $(GOLDEN_RTL)/DelayNWithValid_152.sv $(GOLDEN_RTL)/DelayNWithValid_155.sv \
  $(GOLDEN_RTL)/DelayNWithValid_2.sv $(GOLDEN_RTL)/DelayNWithValid_200.sv \
  $(GOLDEN_RTL)/DelayNWithValid_202.sv $(GOLDEN_RTL)/DelayNWithValid_203.sv \
  $(GOLDEN_RTL)/DelayNWithValid_3.sv $(GOLDEN_RTL)/DelayNWithValid_4.sv \
  $(GOLDEN_RTL)/DelayNWithValid_52.sv $(GOLDEN_RTL)/DelayNWithValid_55.sv \
  $(GOLDEN_RTL)/DelayNWithValid_7.sv $(GOLDEN_RTL)/DelayN_1.sv \
  $(GOLDEN_RTL)/DelayN_13.sv $(GOLDEN_RTL)/DelayN_221.sv \
  $(GOLDEN_RTL)/DelayN_222.sv $(GOLDEN_RTL)/DelayN_226.sv \
  $(GOLDEN_RTL)/DelayN_298.sv $(GOLDEN_RTL)/DelayN_332.sv \
  $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_8.sv \
  $(GOLDEN_RTL)/DelayN_9.sv $(GOLDEN_RTL)/DiffExtLrScEvent.v \
  $(GOLDEN_RTL)/DelayReg_21.sv $(GOLDEN_RTL)/DelayReg_22.sv $(GOLDEN_RTL)/DelayReg_23.sv \
  $(GOLDEN_RTL)/DummyDPICWrapper_50.sv $(GOLDEN_RTL)/DuplicatedTagArray.sv \
  $(GOLDEN_RTL)/FDPrefetcherMonitor.sv $(GOLDEN_RTL)/FastArbiter.sv \
  $(GOLDEN_RTL)/FreeList.sv $(GOLDEN_RTL)/FreeList_1.sv \
  $(GOLDEN_RTL)/FreeList_3.sv $(GOLDEN_RTL)/FreeList_4.sv \
  $(GOLDEN_RTL)/FreeList_5.sv $(GOLDEN_RTL)/FreeList_6.sv \
  $(GOLDEN_RTL)/FrontendBridge.sv $(GOLDEN_RTL)/HPTW.sv \
  $(GOLDEN_RTL)/HPerfCounter_21.sv $(GOLDEN_RTL)/HPerfMonitor_3.sv \
  $(GOLDEN_RTL)/ICacheBuffer.sv $(GOLDEN_RTL)/ICacheCtrlBuffer.sv \
  $(GOLDEN_RTL)/InstrUncacheBuffer.sv $(GOLDEN_RTL)/L1CohMetaArray.sv \
  $(GOLDEN_RTL)/L1FlagMetaArray.sv $(GOLDEN_RTL)/L1FlagMetaArray_1.sv \
  $(GOLDEN_RTL)/L1PrefetchSourceArray.sv $(GOLDEN_RTL)/L1Prefetcher.sv \
  $(GOLDEN_RTL)/L2TLB.sv $(GOLDEN_RTL)/L2TLBWrapper.sv \
  $(GOLDEN_RTL)/L2TlbMissQueue.sv $(GOLDEN_RTL)/L2TlbPrefetch.sv \
  $(GOLDEN_RTL)/LLPTW.sv $(GOLDEN_RTL)/LoadMisalignBuffer.sv \
  $(GOLDEN_RTL)/LoadPipe.sv $(GOLDEN_RTL)/LoadQueue.sv \
  $(GOLDEN_RTL)/LoadQueueRAR.sv $(GOLDEN_RTL)/LoadQueueRAW.sv \
  $(GOLDEN_RTL)/LoadQueueReplay.sv $(GOLDEN_RTL)/LoadQueueUncache.sv \
  $(GOLDEN_RTL)/LoadUnit.sv $(GOLDEN_RTL)/LqExceptionBuffer.sv \
  $(GOLDEN_RTL)/LqMaskModule.sv $(GOLDEN_RTL)/LqPAddrModule.sv \
  $(GOLDEN_RTL)/LqPAddrModule_1.sv $(GOLDEN_RTL)/LqVAddrModule.sv \
  $(GOLDEN_RTL)/LsqWrapper.sv $(GOLDEN_RTL)/MainPipe.sv \
  $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/MbistIntfMemBlk.sv \
  $(GOLDEN_RTL)/MbistPipeDCacheData.sv $(GOLDEN_RTL)/MbistPipeDcacheTag.sv \
  $(GOLDEN_RTL)/MbistPipeMemBlk.sv $(GOLDEN_RTL)/MbistPipePtwL0.sv \
  $(GOLDEN_RTL)/MbistPipePtwL1.sv $(GOLDEN_RTL)/MbistPipeSms.sv \
  $(GOLDEN_RTL)/MemExeUnit.sv $(GOLDEN_RTL)/MemTrigger.sv \
  $(GOLDEN_RTL)/MemTrigger_3.sv $(GOLDEN_RTL)/MissEntry.sv \
  $(GOLDEN_RTL)/MissQueue.sv $(GOLDEN_RTL)/MissReadyGen.sv \
  $(GOLDEN_RTL)/MutiLevelPrefetchFilter.sv $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv \
  $(GOLDEN_RTL)/NewPipelineConnectPipe_31.sv $(GOLDEN_RTL)/NewPipelineConnectPipe_32.sv \
  $(GOLDEN_RTL)/NewPipelineConnectPipe_33.sv $(GOLDEN_RTL)/OverrideableQueue.sv \
  $(GOLDEN_RTL)/OverrideableQueue_1.sv $(GOLDEN_RTL)/PFEvent.sv \
  $(GOLDEN_RTL)/PMP.sv $(GOLDEN_RTL)/PMPChecker.sv \
  $(GOLDEN_RTL)/PMPChecker_10.sv $(GOLDEN_RTL)/PTW.sv \
  $(GOLDEN_RTL)/PTWFilterEntry.sv $(GOLDEN_RTL)/PTWFilterEntry_1.sv \
  $(GOLDEN_RTL)/PTWNewFilter.sv $(GOLDEN_RTL)/PTWRepeaterNB.sv \
  $(GOLDEN_RTL)/PatternHistoryTable.sv $(GOLDEN_RTL)/Pipeline.sv \
  $(GOLDEN_RTL)/PipelineRegModule.sv $(GOLDEN_RTL)/PipelineRegModule_1.sv \
  $(GOLDEN_RTL)/PipelineRegModule_2.sv $(GOLDEN_RTL)/PipelineRegModule_6.sv \
  $(GOLDEN_RTL)/PrefetchBurstGenerator.sv $(GOLDEN_RTL)/PrefetchFilter.sv \
  $(GOLDEN_RTL)/PrefetcherMonitor.sv $(GOLDEN_RTL)/ProbeEntry.sv \
  $(GOLDEN_RTL)/ProbeQueue.sv $(GOLDEN_RTL)/PtwCache.sv \
  $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv $(GOLDEN_RTL)/Queue1_RegMapperInput_4.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_14.sv $(GOLDEN_RTL)/Queue2_TLBundleA_15.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv $(GOLDEN_RTL)/Queue2_TLBundleA_7.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_8.sv $(GOLDEN_RTL)/Queue2_TLBundleB.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleC.sv $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv $(GOLDEN_RTL)/Queue2_TLBundleD_8.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleD_9.sv $(GOLDEN_RTL)/Queue2_TLBundleE.sv \
  $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv $(GOLDEN_RTL)/RRArbiterInit.sv \
  $(GOLDEN_RTL)/RRArbiterInit_10.sv $(GOLDEN_RTL)/RRArbiterInit_3.sv \
  $(GOLDEN_RTL)/RRArbiterInit_4.sv $(GOLDEN_RTL)/RRArbiterInit_5.sv \
  $(GOLDEN_RTL)/RRArbiterInit_6.sv $(GOLDEN_RTL)/RRArbiterInit_7.sv \
  $(GOLDEN_RTL)/RRArbiterInit_9.sv $(GOLDEN_RTL)/SMSPrefetcher.sv \
  $(GOLDEN_RTL)/SMSTrainFilter.sv $(GOLDEN_RTL)/SQAddrModule.sv \
  $(GOLDEN_RTL)/SQAddrModule_1.sv $(GOLDEN_RTL)/SQData8Module.sv \
  $(GOLDEN_RTL)/SQDataModule.sv $(GOLDEN_RTL)/SRAMTemplate_114.sv \
  $(GOLDEN_RTL)/SRAMTemplate_122.sv $(GOLDEN_RTL)/SRAMTemplate_126.sv \
  $(GOLDEN_RTL)/SRAMTemplate_134.sv $(GOLDEN_RTL)/SRAMTemplate_82.sv \
  $(GOLDEN_RTL)/SRAMTemplate_84.sv $(GOLDEN_RTL)/SRAMTemplate_86.sv \
  $(GOLDEN_RTL)/SRAMTemplate_90.sv $(GOLDEN_RTL)/SRAMTemplate_98.sv \
  $(GOLDEN_RTL)/Sbuffer.sv $(GOLDEN_RTL)/SbufferData.sv \
  $(GOLDEN_RTL)/Serializer.sv $(GOLDEN_RTL)/SplittedSRAM.sv \
  $(GOLDEN_RTL)/SplittedSRAM_1.sv $(GOLDEN_RTL)/Std.sv \
  $(GOLDEN_RTL)/StoreExceptionBuffer.sv $(GOLDEN_RTL)/StoreMisalignBuffer.sv \
  $(GOLDEN_RTL)/StorePfWrapper.sv $(GOLDEN_RTL)/StorePipe.sv \
  $(GOLDEN_RTL)/StorePrefetchBursts.sv $(GOLDEN_RTL)/StoreQueue.sv \
  $(GOLDEN_RTL)/StoreUnit.sv $(GOLDEN_RTL)/StreamBitVectorArray.sv \
  $(GOLDEN_RTL)/StrideMetaArray.sv $(GOLDEN_RTL)/StridePF.sv \
  $(GOLDEN_RTL)/TLBFA_1.sv $(GOLDEN_RTL)/TLBFA_2.sv \
  $(GOLDEN_RTL)/TLBFA_3.sv $(GOLDEN_RTL)/TLBNonBlock.sv \
  $(GOLDEN_RTL)/TLBNonBlock_1.sv $(GOLDEN_RTL)/TLBNonBlock_2.sv \
  $(GOLDEN_RTL)/TLBuffer_6.sv $(GOLDEN_RTL)/TLBuffer_7.sv \
  $(GOLDEN_RTL)/TLBuffer_8.sv $(GOLDEN_RTL)/TLBuffer_9.sv \
  $(GOLDEN_RTL)/TLXbar_4.sv $(GOLDEN_RTL)/TagArray.sv \
  $(GOLDEN_RTL)/TagSRAMBank.sv $(GOLDEN_RTL)/TlbStorageWrapper_1.sv \
  $(GOLDEN_RTL)/TlbStorageWrapper_2.sv $(GOLDEN_RTL)/TlbStorageWrapper_3.sv \
  $(GOLDEN_RTL)/TrainFilter.sv $(GOLDEN_RTL)/TrainFilter_1.sv \
  $(GOLDEN_RTL)/TreeArbiter.sv $(GOLDEN_RTL)/Uncache.sv \
  $(GOLDEN_RTL)/UncacheEntry.sv $(GOLDEN_RTL)/UncacheEntry_1.sv \
  $(GOLDEN_RTL)/UncacheEntry_2.sv $(GOLDEN_RTL)/UncacheEntry_3.sv \
  $(GOLDEN_RTL)/VLMergeBufferImp.sv $(GOLDEN_RTL)/VLSplitBufferImp.sv \
  $(GOLDEN_RTL)/VLSplitImp.sv $(GOLDEN_RTL)/VLSplitPipelineImp.sv \
  $(GOLDEN_RTL)/VSMergeBufferImp.sv $(GOLDEN_RTL)/VSSplitBufferImp.sv \
  $(GOLDEN_RTL)/VSSplitImp.sv $(GOLDEN_RTL)/VSSplitPipelineImp.sv \
  $(GOLDEN_RTL)/VSegmentTrigger.sv $(GOLDEN_RTL)/VSegmentUnit.sv \
  $(GOLDEN_RTL)/VfofBuffer.sv $(GOLDEN_RTL)/VirtualLoadQueue.sv \
  $(GOLDEN_RTL)/WritebackEntry.sv $(GOLDEN_RTL)/WritebackEntry_15.sv \
  $(GOLDEN_RTL)/WritebackQueue.sv $(GOLDEN_RTL)/array_10.sv \
  $(GOLDEN_RTL)/array_10_ext.v $(GOLDEN_RTL)/array_11.sv \
  $(GOLDEN_RTL)/array_11_ext.v $(GOLDEN_RTL)/array_12.sv \
  $(GOLDEN_RTL)/array_12_ext.v $(GOLDEN_RTL)/array_8.sv \
  $(GOLDEN_RTL)/array_8_ext.v $(GOLDEN_RTL)/array_9.sv \
  $(GOLDEN_RTL)/array_9_ext.v $(GOLDEN_RTL)/perfEventsModule.sv \
  $(GOLDEN_RTL)/ram_2x114.sv $(GOLDEN_RTL)/ram_2x115.sv \
  $(GOLDEN_RTL)/ram_2x131.sv $(GOLDEN_RTL)/ram_2x134.sv \
  $(GOLDEN_RTL)/ram_2x280.sv $(GOLDEN_RTL)/ram_2x281.sv \
  $(GOLDEN_RTL)/ram_2x284.sv $(GOLDEN_RTL)/ram_2x309.sv \
  $(GOLDEN_RTL)/ram_2x355.sv $(GOLDEN_RTL)/ram_2x359.sv \
  $(GOLDEN_RTL)/ram_2x373.sv $(GOLDEN_RTL)/ram_2x406.sv \
  $(GOLDEN_RTL)/ram_2x76.sv $(GOLDEN_RTL)/ram_2x77.sv \
  $(GOLDEN_RTL)/ram_2x78.sv $(GOLDEN_RTL)/ram_40x47.sv \
  $(GOLDEN_RTL)/ram_sink_2x10.sv $(GOLDEN_RTL)/skidBufferConnect.sv \
  $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
  $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv $(GOLDEN_RTL)/sram_array_1p32x228m114s1h0l1b_ptw_l0.sv \
  $(GOLDEN_RTL)/sram_array_1p8x200m100s1h0l1b_ptw_l1.sv

FM_VARIANTS =

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert(非综合); BT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh(端口表/内部网/顶层逻辑/perf) 与本目录的
# memblock_inst_bt.svh(BT 换核实例表)。本目录优先, rtl/memblock 兜底。
VCS += +incdir+. +incdir+$(RTL_DIR)/memblock
# 运行加 +vcs+initreg+0(照 BT 任务要求 / Backend BT)。实测对本子系统结果中性(加不加
# 8665==8665):发散主体是 golden(Jun-24 bump)与重写 glue(Jun-16)的接口失配, 非未初始化寄存器,
# initreg+0 既不引入也不消除。详见 README §2(基线回归根因)。
SIM_ARGS += +vcs+initreg+0
