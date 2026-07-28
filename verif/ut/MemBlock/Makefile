MODULE = MemBlock

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（核通过 `include 引入端口表 / 内部网 / 顶层逻辑 / perf / 实例表）。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_pkg.sv \
           $(RTL_DIR)/memblock/MemBlock.sv

TB_SRCS = variants_xs.sv tb.sv

# golden MemBlock 例化访存子系统全部组件，其传递闭包共 273 个 golden 文件
# （整个访存子系统：DCache 全栈 + L2TLB/PTW + 全部队列 + 厂商 SRAM 宏 *_ext.v + ClockGate）。
# UT 双例化两侧（golden 顶层 + 手写可读核）都读入这批 golden 子模块定义。
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

# FM 走黑盒先例（见 fm_eq_bb.tcl）：ref/impl 两侧都只读顶层 + memblock_stub（全部
# 子模块显式端口黑盒），避免厂商 RAM(ram_40x47 异步读)在 link 触发 FMR_ELAB-147，
# 并把比对聚焦在本层互联 glue。共享 fm-% 规则会整树 link golden 子模块而失败，故不用。
FM_VARIANTS =
FM_BB_TARGET = fmbb

# 子模块条目结构相同的重复寄存器很多，关掉“合并同值重复寄存器”pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口表 / 内部网 / 顶层逻辑 / perf / 实例表）。
VCS += +incdir+$(RTL_DIR)/memblock

# ----------------------------------------------------------------------------
# assembly FM 目标（codex_0074 owner#6）：
#   ref  = golden MemBlock + 34 类黑盒桩(memblock_bb_stub) + 26 glue golden closure
#   impl = wrapper(→核+pkg) + 同一 34 类黑盒桩 + 同一 26 glue golden closure
#
#   黑盒(34 类, memblock_bb_stub.sv)= 20 green-305 SIGNOFF_PASS + 14 aux-PASS child：
#     两侧显式端口方向黑盒(identity 配对)——依赖闭合，合法对称 unresolved 黑盒。
#   两侧 elaborate(26 glue golden)= HPerfMonitor_3(→HPerfCounter_21)/PFEvent(→perfEventsModule)/
#     FrontendBridge(→ICacheBuffer/ICacheCtrlBuffer/InstrUncacheBuffer→Queue2×6)/
#     MbistIntfMemBlk/MbistPipeMemBlk/MbistPipeSms/DelayN_332/DelayN_8/DelayNWithValid_{2,200,202,203,3}/
#     PipelineRegModule/PipelineRegModule_6：本层 glue 真实功能(perf 汇聚/MBIST 分发/打拍)必须两侧
#     真实 elaborate 非黑盒——尤其 HPerfMonitor_3 驱动 io_perf_*，黑盒会致 perf pipeline 假失配。
#   厂商 SRAM 宏不在此层(glue 无 SRAM)；黑盒 34 类的内部 SRAM 随其黑盒消隐。
# ----------------------------------------------------------------------------
BB_STUB = $(abspath $(RTL_DIR)/memblock/memblock_bb_stub.sv)
# glue elaborate 闭包(两侧共读)
GLUE_GOLDEN = $(GOLDEN_RTL)/HPerfMonitor_3.sv $(GOLDEN_RTL)/HPerfCounter_21.sv \
  $(GOLDEN_RTL)/PFEvent.sv $(GOLDEN_RTL)/perfEventsModule.sv \
  $(GOLDEN_RTL)/FrontendBridge.sv $(GOLDEN_RTL)/ICacheBuffer.sv \
  $(GOLDEN_RTL)/ICacheCtrlBuffer.sv $(GOLDEN_RTL)/InstrUncacheBuffer.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_8.sv $(GOLDEN_RTL)/Queue2_TLBundleD_9.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
  $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv \
  $(GOLDEN_RTL)/MbistIntfMemBlk.sv $(GOLDEN_RTL)/MbistPipeMemBlk.sv \
  $(GOLDEN_RTL)/MbistPipeSms.sv \
  $(GOLDEN_RTL)/DelayN_332.sv $(GOLDEN_RTL)/DelayN_8.sv \
  $(GOLDEN_RTL)/DelayNWithValid_2.sv $(GOLDEN_RTL)/DelayNWithValid_200.sv \
  $(GOLDEN_RTL)/DelayNWithValid_202.sv $(GOLDEN_RTL)/DelayNWithValid_203.sv \
  $(GOLDEN_RTL)/DelayNWithValid_3.sv \
  $(GOLDEN_RTL)/PipelineRegModule.sv $(GOLDEN_RTL)/PipelineRegModule_6.sv
.PHONY: fmbb
fmbb:
	@[ -n "$$FM_SIDECAR_OUT" ] || { echo "ERROR($(MODULE)): fmbb 须经 sidecar runner"; exit 1; }
	@mkdir -p fm_work/MemBlock
	@echo "=== FM(bb): MemBlock ==="
	FM_TOP=MemBlock \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/MemBlock.sv) $(BB_STUB) $(abspath $(GLUE_GOLDEN))" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS)) $(abspath $(RTL_DIR)/memblock/MemBlock_wrapper.sv) $(BB_STUB) $(abspath $(GLUE_GOLDEN))" \
	FM_MERGE_DUP=false \
	XSSV_HOME=$(XSSV_HOME) FM_RUN_ID=$$FM_RUN_ID \
	fm_shell -64 -work_path fm_work/MemBlock -file $(abspath fm_eq_bb.tcl) \
	    > fm_work/MemBlock/fm.log 2>&1; \
	rc=$$?; echo $$rc > "$$FM_SIDECAR_OUT/fm_shell.rc"; \
	grep -E "^FM_RESULT" fm_work/MemBlock/fm.log || true
