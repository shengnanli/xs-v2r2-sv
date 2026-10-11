MODULE = MemBlock

# MemBlock —— 访存子系统顶层装配（golden 57,550 行 / 2,450 端口 / 72 个直接子模块 / 本层 388 个寄存器）。
# 重写件 rtl/memblock/MemBlock.sv = 可读核 xs_MemBlock_core（手写）+ golden 同名 wrapper（scripts/gen_memblock.py 生成）。
#
# UT（取舍说明）：双例化 golden MemBlock 与派生 MemBlock_xs，两侧的 72 个子模块**同一份 golden 定义**（RTL_GOLDEN_DEPS，
#   golden MemBlock 的整棵子树 292 个文件，ClockGate 用本地件），比的只是 MemBlock 本层：可读核的胶合逻辑 / 388 个寄存器
#   与 wrapper 的 72 个例化连线、字段束拼装。子模块各自已独立签核（证书见 verif/allow/MemBlock.json），这与 FM 的
#   green_child 组合同构；若 impl 侧再换成整棵重写子树，UT 闭包会在 golden 的 ~290 个文件之外再加 ~400 个重写文件，
#   编译 / 仿真代价翻倍而增加的只是子模块重复验证。
#   初值档只跑 +vcs+initreg+0 / +1 两个常量档：两侧子模块（SRAM 阵列、不复位的表项）若用 random 会各摇各的，
#   比出来的是初值噪声（L2TLB / Frontend 先例，CONVENTIONS「双例化 UT」）。
# FM：见 FM_VARIANTS 一节 —— 72 个直接实例（50 种 design）全部 exact green_child，只有本层 glue 白盒。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MemBlock.sv
TB_SRCS = tb.sv

# UT 两侧共用的 golden 子树（golden MemBlock 的传递闭包，ClockGate 换成本地件）
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
    $(GOLDEN_RTL)/L2TLBWrapper.sv \
    $(GOLDEN_RTL)/L2TLB.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TlbWithHptwIdBundle.sv \
    $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/Arbiter2_PtwReq.sv \
    $(GOLDEN_RTL)/PtwCache.sv \
    $(GOLDEN_RTL)/MbistPipePtwL0.sv \
    $(GOLDEN_RTL)/MbistPipePtwL1.sv \
    $(GOLDEN_RTL)/SplittedSRAM_2.sv \
    $(GOLDEN_RTL)/SRAMTemplate_129.sv \
    $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
    $(GOLDEN_RTL)/array_11.sv \
    $(GOLDEN_RTL)/array_11_ext.v \
    $(GOLDEN_RTL)/SRAMTemplate_143.sv \
    $(GOLDEN_RTL)/SplittedSRAM_1.sv \
    $(GOLDEN_RTL)/SRAMTemplate_128.sv \
    $(GOLDEN_RTL)/sram_array_1p4x786m131s1h0l1b_ptw_l1.sv \
    $(GOLDEN_RTL)/array_10.sv \
    $(GOLDEN_RTL)/array_10_ext.v \
    $(GOLDEN_RTL)/Arbiter5_L2TlbWithHptwIdBundle.sv \
    $(GOLDEN_RTL)/PTW.sv \
    $(GOLDEN_RTL)/Arbiter1_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/L2TlbPrefetch.sv \
    $(GOLDEN_RTL)/DelayN_220.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon.sv \
    $(GOLDEN_RTL)/DelayN_221.sv \
    $(GOLDEN_RTL)/BitmapCache.sv \
    $(GOLDEN_RTL)/SplittedSRAM.sv \
    $(GOLDEN_RTL)/SRAMTemplate_124.sv \
    $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
    $(GOLDEN_RTL)/array_9.sv \
    $(GOLDEN_RTL)/array_9_ext.v \
    $(GOLDEN_RTL)/MbistBitmapCache.sv \
    $(GOLDEN_RTL)/PMP.sv \
    $(GOLDEN_RTL)/Bitmap.sv \
    $(GOLDEN_RTL)/Arbiter8_bitmapCacheReqBundle.sv \
    $(GOLDEN_RTL)/RRArbiterInit.sv \
    $(GOLDEN_RTL)/HPTW.sv \
    $(GOLDEN_RTL)/L2TlbMissQueue.sv \
    $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
    $(GOLDEN_RTL)/ram_40x47.sv \
    $(GOLDEN_RTL)/PMPChecker.sv \
    $(GOLDEN_RTL)/DelayN_13.sv \
    $(GOLDEN_RTL)/Arbiter3_bitmapReqBundle.sv \
    $(GOLDEN_RTL)/Arbiter2_L2TLBImp_Anon_1.sv \
    $(GOLDEN_RTL)/Arbiter4_L2TlbMemReqBundle.sv \
    $(GOLDEN_RTL)/LLPTW.sv \
    $(GOLDEN_RTL)/RRArbiterInit_4.sv \
    $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv \
    $(GOLDEN_RTL)/RRArbiterInit_1.sv \
    $(GOLDEN_RTL)/L1Prefetcher.sv \
    $(GOLDEN_RTL)/StrideMetaArray.sv \
    $(GOLDEN_RTL)/TrainFilter.sv \
    $(GOLDEN_RTL)/MutiLevelPrefetchFilter.sv \
    $(GOLDEN_RTL)/RRArbiterInit_7.sv \
    $(GOLDEN_RTL)/RRArbiterInit_8.sv \
    $(GOLDEN_RTL)/RRArbiterInit_9.sv \
    $(GOLDEN_RTL)/RRArbiterInit_6.sv \
    $(GOLDEN_RTL)/StreamBitVectorArray.sv \
    $(GOLDEN_RTL)/TrainFilter_1.sv \
    $(GOLDEN_RTL)/PFEvent.sv \
    $(GOLDEN_RTL)/perfEventsModule.sv \
    $(GOLDEN_RTL)/TLBNonBlock.sv \
    $(GOLDEN_RTL)/DelayN_9.sv \
    $(GOLDEN_RTL)/TlbStorageWrapper_1.sv \
    $(GOLDEN_RTL)/TLBFA_1.sv \
    $(GOLDEN_RTL)/DelayN_7.sv \
    $(GOLDEN_RTL)/DelayNWithValid_2.sv \
    $(GOLDEN_RTL)/Pipeline.sv \
    $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv \
    $(GOLDEN_RTL)/LoadMisalignBuffer.sv \
    $(GOLDEN_RTL)/NewPipelineConnectPipe_35.sv \
    $(GOLDEN_RTL)/StoreMisalignBuffer.sv \
    $(GOLDEN_RTL)/TLBNonBlock_1.sv \
    $(GOLDEN_RTL)/TlbStorageWrapper_2.sv \
    $(GOLDEN_RTL)/TLBFA_2.sv \
    $(GOLDEN_RTL)/VSMergeBufferImp.sv \
    $(GOLDEN_RTL)/NewPipelineConnectPipe_29.sv \
    $(GOLDEN_RTL)/FreeList_1.sv \
    $(GOLDEN_RTL)/TLBuffer_7.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_7.sv \
    $(GOLDEN_RTL)/ram_2x406.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleD_8.sv \
    $(GOLDEN_RTL)/ram_2x284.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleB.sv \
    $(GOLDEN_RTL)/ram_2x309.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleC.sv \
    $(GOLDEN_RTL)/ram_2x373.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleE.sv \
    $(GOLDEN_RTL)/ram_sink_2x10.sv \
    $(GOLDEN_RTL)/HPerfMonitor_3.sv \
    $(GOLDEN_RTL)/HPerfCounter_21.sv \
    $(GOLDEN_RTL)/MbistPipeMemBlk.sv \
    $(GOLDEN_RTL)/DelayN_333.sv \
    $(GOLDEN_RTL)/StoreUnit.sv \
    $(GOLDEN_RTL)/MemTrigger_3.sv \
    $(GOLDEN_RTL)/VSegmentUnit.sv \
    $(GOLDEN_RTL)/NewPipelineConnectPipe_33.sv \
    $(GOLDEN_RTL)/VSegmentTrigger.sv \
    $(GOLDEN_RTL)/MemExeUnit.sv \
    $(GOLDEN_RTL)/Std.sv \
    $(GOLDEN_RTL)/Uncache.sv \
    $(GOLDEN_RTL)/DelayN_331.sv \
    $(GOLDEN_RTL)/TLBuffer_8.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
    $(GOLDEN_RTL)/ram_2x79.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_14.sv \
    $(GOLDEN_RTL)/ram_2x136.sv \
    $(GOLDEN_RTL)/VSSplitImp.sv \
    $(GOLDEN_RTL)/skidBufferConnect.sv \
    $(GOLDEN_RTL)/VSSplitPipelineImp.sv \
    $(GOLDEN_RTL)/VSSplitBufferImp.sv \
    $(GOLDEN_RTL)/TLBuffer_9.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_15.sv \
    $(GOLDEN_RTL)/ram_2x116.sv \
    $(GOLDEN_RTL)/DelayNWithValid_202.sv \
    $(GOLDEN_RTL)/PTWRepeaterNB.sv \
    $(GOLDEN_RTL)/DelayN_1.sv \
    $(GOLDEN_RTL)/PipelineRegModule.sv \
    $(GOLDEN_RTL)/DelayNWithValid_3.sv \
    $(GOLDEN_RTL)/DelayNWithValid_200.sv \
    $(GOLDEN_RTL)/Sbuffer.sv \
    $(GOLDEN_RTL)/StorePfWrapper.sv \
    $(GOLDEN_RTL)/Serializer.sv \
    $(GOLDEN_RTL)/SbufferData.sv \
    $(GOLDEN_RTL)/DelayN_8.sv \
    $(GOLDEN_RTL)/NewPipelineConnectPipe_34.sv \
    $(GOLDEN_RTL)/MbistIntfMemBlk.sv \
    $(GOLDEN_RTL)/FrontendBridge.sv \
    $(GOLDEN_RTL)/ICacheCtrlBuffer.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
    $(GOLDEN_RTL)/ram_2x80.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv \
    $(GOLDEN_RTL)/ram_2x117.sv \
    $(GOLDEN_RTL)/InstrUncacheBuffer.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
    $(GOLDEN_RTL)/ram_2x133.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv \
    $(GOLDEN_RTL)/ram_2x76.sv \
    $(GOLDEN_RTL)/ICacheBuffer.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_8.sv \
    $(GOLDEN_RTL)/ram_2x359.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
    $(GOLDEN_RTL)/ram_2x281.sv \
    $(GOLDEN_RTL)/VLSplitImp.sv \
    $(GOLDEN_RTL)/VLSplitBufferImp.sv \
    $(GOLDEN_RTL)/VLSplitPipelineImp.sv \
    $(GOLDEN_RTL)/AtomicsUnit.sv \
    $(GOLDEN_RTL)/DelayNWithValid_203.sv \
    $(GOLDEN_RTL)/VfofBuffer.sv \
    $(GOLDEN_RTL)/TLXbar_4.sv \
    $(GOLDEN_RTL)/PipelineRegModule_6.sv \
    $(GOLDEN_RTL)/DCacheWrapper.sv \
    $(GOLDEN_RTL)/DCache.sv \
    $(GOLDEN_RTL)/StorePipe.sv \
    $(GOLDEN_RTL)/CtrlUnit.sv \
    $(GOLDEN_RTL)/Queue1_RegMapperInput_6.sv \
    $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv \
    $(GOLDEN_RTL)/DuplicatedTagArray.sv \
    $(GOLDEN_RTL)/MbistPipeDcacheTag.sv \
    $(GOLDEN_RTL)/TagArray.sv \
    $(GOLDEN_RTL)/TagSRAMBank.sv \
    $(GOLDEN_RTL)/SRAMTemplate_116.sv \
    $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
    $(GOLDEN_RTL)/array_8.sv \
    $(GOLDEN_RTL)/array_8_ext.v \
    $(GOLDEN_RTL)/MbistClockGateCell.sv \
    $(GOLDEN_RTL)/WritebackQueue.sv \
    $(GOLDEN_RTL)/WritebackEntry_15.sv \
    $(GOLDEN_RTL)/WritebackEntry.sv \
    $(GOLDEN_RTL)/L1CohMetaArray.sv \
    $(GOLDEN_RTL)/CounterFilter.sv \
    $(GOLDEN_RTL)/MainPipe.sv \
    $(GOLDEN_RTL)/AMOALU.sv \
    $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv \
    $(GOLDEN_RTL)/L1FlagMetaArray.sv \
    $(GOLDEN_RTL)/L1ErrorMetaArray.sv \
    $(GOLDEN_RTL)/MissQueue.sv \
    $(GOLDEN_RTL)/Arbiter16_MainPipeReq.sv \
    $(GOLDEN_RTL)/MissEntry.sv \
    $(GOLDEN_RTL)/CMOUnit.sv \
    $(GOLDEN_RTL)/FDPrefetcherMonitor.sv \
    $(GOLDEN_RTL)/TreeArbiter.sv \
    $(GOLDEN_RTL)/PrefetcherMonitor.sv \
    $(GOLDEN_RTL)/L1PrefetchSourceArray.sv \
    $(GOLDEN_RTL)/BloomFilter.sv \
    $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReq.sv \
    $(GOLDEN_RTL)/MissReadyGen.sv \
    $(GOLDEN_RTL)/Arbiter1_TagWriteReq.sv \
    $(GOLDEN_RTL)/ProbeQueue.sv \
    $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv \
    $(GOLDEN_RTL)/ProbeEntry.sv \
    $(GOLDEN_RTL)/Arbiter1_L1BankedDataWriteReqCtrl.sv \
    $(GOLDEN_RTL)/LoadPipe.sv \
    $(GOLDEN_RTL)/BankedDataArray.sv \
    $(GOLDEN_RTL)/DataSRAMBank_1.sv \
    $(GOLDEN_RTL)/SRAMTemplate_88.sv \
    $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
    $(GOLDEN_RTL)/array_7.sv \
    $(GOLDEN_RTL)/array_7_ext.v \
    $(GOLDEN_RTL)/MbistPipeDCacheData.sv \
    $(GOLDEN_RTL)/DataSRAMBank_4.sv \
    $(GOLDEN_RTL)/SRAMTemplate_100.sv \
    $(GOLDEN_RTL)/DataSRAMBank_2.sv \
    $(GOLDEN_RTL)/SRAMTemplate_92.sv \
    $(GOLDEN_RTL)/DataSRAMBank.sv \
    $(GOLDEN_RTL)/SRAMTemplate_84.sv \
    $(GOLDEN_RTL)/SRAMTemplate_86.sv \
    $(GOLDEN_RTL)/LoadUnit.sv \
    $(GOLDEN_RTL)/MemTrigger.sv \
    $(GOLDEN_RTL)/VLMergeBufferImp.sv \
    $(GOLDEN_RTL)/FreeList.sv \
    $(GOLDEN_RTL)/PMPChecker_12.sv \
    $(GOLDEN_RTL)/TLBNonBlock_2.sv \
    $(GOLDEN_RTL)/TlbStorageWrapper_3.sv \
    $(GOLDEN_RTL)/TLBFA_3.sv \
    $(GOLDEN_RTL)/PTWNewFilter.sv \
    $(GOLDEN_RTL)/PTWFilterEntry.sv \
    $(GOLDEN_RTL)/PTWFilterEntry_1.sv \
    $(GOLDEN_RTL)/RRArbiterInit_12.sv \
    $(GOLDEN_RTL)/LsqWrapper.sv \
    $(GOLDEN_RTL)/LoadQueue.sv \
    $(GOLDEN_RTL)/VirtualLoadQueue.sv \
    $(GOLDEN_RTL)/LoadQueueRAR.sv \
    $(GOLDEN_RTL)/LqPAddrModule.sv \
    $(GOLDEN_RTL)/DelayNWithValid_4.sv \
    $(GOLDEN_RTL)/DelayN_225.sv \
    $(GOLDEN_RTL)/DelayNWithValid_7.sv \
    $(GOLDEN_RTL)/FreeList_3.sv \
    $(GOLDEN_RTL)/LoadQueueUncache.sv \
    $(GOLDEN_RTL)/UncacheEntry_7.sv \
    $(GOLDEN_RTL)/UncacheEntry_12.sv \
    $(GOLDEN_RTL)/FreeList_6.sv \
    $(GOLDEN_RTL)/UncacheEntry_14.sv \
    $(GOLDEN_RTL)/UncacheEntry_1.sv \
    $(GOLDEN_RTL)/UncacheEntry_4.sv \
    $(GOLDEN_RTL)/UncacheEntry_15.sv \
    $(GOLDEN_RTL)/UncacheEntry_6.sv \
    $(GOLDEN_RTL)/UncacheEntry_8.sv \
    $(GOLDEN_RTL)/UncacheEntry_11.sv \
    $(GOLDEN_RTL)/UncacheEntry_10.sv \
    $(GOLDEN_RTL)/UncacheEntry_9.sv \
    $(GOLDEN_RTL)/UncacheEntry_2.sv \
    $(GOLDEN_RTL)/UncacheEntry_13.sv \
    $(GOLDEN_RTL)/RRArbiterInit_11.sv \
    $(GOLDEN_RTL)/UncacheEntry.sv \
    $(GOLDEN_RTL)/PipelineRegModule_1.sv \
    $(GOLDEN_RTL)/UncacheEntry_3.sv \
    $(GOLDEN_RTL)/PipelineRegModule_2.sv \
    $(GOLDEN_RTL)/UncacheEntry_5.sv \
    $(GOLDEN_RTL)/LoadQueueRAW.sv \
    $(GOLDEN_RTL)/DelayNWithValid_148.sv \
    $(GOLDEN_RTL)/LqMaskModule.sv \
    $(GOLDEN_RTL)/DelayNWithValid_52.sv \
    $(GOLDEN_RTL)/DelayNWithValid_103.sv \
    $(GOLDEN_RTL)/LqPAddrModule_1.sv \
    $(GOLDEN_RTL)/DelayNWithValid_55.sv \
    $(GOLDEN_RTL)/DelayN_297.sv \
    $(GOLDEN_RTL)/DelayNWithValid_149.sv \
    $(GOLDEN_RTL)/FreeList_4.sv \
    $(GOLDEN_RTL)/LoadQueueReplay.sv \
    $(GOLDEN_RTL)/FreeList_5.sv \
    $(GOLDEN_RTL)/AgeDetector_38.sv \
    $(GOLDEN_RTL)/LqVAddrModule.sv \
    $(GOLDEN_RTL)/DelayNWithValid_152.sv \
    $(GOLDEN_RTL)/DelayNWithValid_155.sv \
    $(GOLDEN_RTL)/LqExceptionBuffer.sv \
    $(GOLDEN_RTL)/StoreQueue.sv \
    $(GOLDEN_RTL)/StoreExceptionBuffer.sv \
    $(GOLDEN_RTL)/DatamoduleResultBuffer.sv \
    $(GOLDEN_RTL)/SQDataModule.sv \
    $(GOLDEN_RTL)/SQData8Module.sv \
    $(GOLDEN_RTL)/SQAddrModule_1.sv \
    $(GOLDEN_RTL)/SQAddrModule.sv \
    $(GOLDEN_RTL)/SMSPrefetcher.sv \
    $(GOLDEN_RTL)/SMSTrainFilter.sv \
    $(GOLDEN_RTL)/StridePF.sv \
    $(GOLDEN_RTL)/PrefetchFilter.sv \
    $(GOLDEN_RTL)/RRArbiterInit_5.sv \
    $(GOLDEN_RTL)/PatternHistoryTable.sv \
    $(GOLDEN_RTL)/OverrideableQueue.sv \
    $(GOLDEN_RTL)/SRAMTemplate_145.sv \
    $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
    $(GOLDEN_RTL)/array_12.sv \
    $(GOLDEN_RTL)/array_12_ext.v \
    $(GOLDEN_RTL)/OverrideableQueue_1.sv \
    $(GOLDEN_RTL)/Arbiter3_PfGenReq.sv \
    $(GOLDEN_RTL)/ActiveGenerationTable.sv \
    $(GOLDEN_RTL)/MbistPipeSms.sv \
    $(GOLDEN_RTL)/TLBuffer_6.sv \
    $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv \
    $(GOLDEN_RTL)/ram_2x356.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MemBlock.sv

FM_VARIANTS = MemBlock
# ★FM（层次化组合，照 Frontend / codex 0226）★：72 个直接实例全部是 exact green_child —— 各自已独立 official 证明、
# 持有 tracked 证书；两侧都以 -interface_only 读入（对称黑盒），verif/allow/MemBlock.json 逐实例绑定 child 证书 sha256。
# 本层 glue（可读核 + wrapper 连线）两侧白盒受验。
# ref 侧（字面文件名）：50 种直接子模块的 golden 定义（只取端口）。
FM_REF_DEPS_MemBlock = AtomicsUnit.sv DCacheWrapper.sv DelayN_331.sv DelayN_333.sv DelayN_8.sv DelayNWithValid_2.sv \
                       DelayNWithValid_200.sv DelayNWithValid_202.sv DelayNWithValid_203.sv DelayNWithValid_3.sv FrontendBridge.sv HPerfMonitor_3.sv \
                       L1Prefetcher.sv L2TLBWrapper.sv LoadMisalignBuffer.sv LoadUnit.sv LsqWrapper.sv MbistIntfMemBlk.sv \
                       MbistPipeMemBlk.sv MbistPipeSms.sv MemExeUnit.sv NewPipelineConnectPipe_34.sv NewPipelineConnectPipe_35.sv PFEvent.sv \
                       Pipeline.sv PipelineRegModule.sv PipelineRegModule_6.sv PMP.sv PMPChecker_12.sv PTWNewFilter.sv \
                       PTWRepeaterNB.sv Sbuffer.sv SMSPrefetcher.sv StoreMisalignBuffer.sv StoreUnit.sv TLBNonBlock.sv \
                       TLBNonBlock_1.sv TLBNonBlock_2.sv TLBuffer_6.sv TLBuffer_7.sv TLBuffer_8.sv TLBuffer_9.sv \
                       TLXbar_4.sv Uncache.sv VfofBuffer.sv VLMergeBufferImp.sv VLSplitImp.sv VSegmentUnit.sv \
                       VSMergeBufferImp.sv VSSplitImp.sv
# impl 侧：50 种直接子模块的重写 wrapper（只取端口）+ 它们 import 的 package（定义 package 的文件排前）+ 本层重写件。
FM_IMPL_RTL = $(XSSV_HOME)/rtl/memblock/memblock_common_pkg.sv $(XSSV_HOME)/rtl/memblock/vmergebuffer_pkg.sv $(XSSV_HOME)/rtl/memblock/vlsu_pkg.sv \
              $(XSSV_HOME)/rtl/memblock/vsegment_pkg.sv $(XSSV_HOME)/rtl/memblock/AtomicsUnit.sv $(XSSV_HOME)/rtl/memblock/DCacheWrapper.sv \
              $(XSSV_HOME)/rtl/common/DelayN_331.sv $(XSSV_HOME)/rtl/common/DelayN_333.sv $(XSSV_HOME)/rtl/common/DelayN_8.sv \
              $(XSSV_HOME)/rtl/common/DelayNWithValid_2.sv $(XSSV_HOME)/rtl/common/DelayNWithValid_200.sv $(XSSV_HOME)/rtl/common/DelayNWithValid_202.sv \
              $(XSSV_HOME)/rtl/common/DelayNWithValid_203.sv $(XSSV_HOME)/rtl/common/DelayNWithValid_3.sv $(XSSV_HOME)/rtl/memblock/FrontendBridge.sv \
              $(XSSV_HOME)/rtl/common/HPerfMonitor_3.sv $(XSSV_HOME)/rtl/memblock/L1Prefetcher.sv $(XSSV_HOME)/rtl/mmu/L2TLBWrapper.sv \
              $(XSSV_HOME)/rtl/memblock/LoadMisalignBuffer.sv $(XSSV_HOME)/rtl/memblock/LoadUnit.sv $(XSSV_HOME)/rtl/memblock/LsqWrapper.sv \
              $(XSSV_HOME)/rtl/memblock/MbistIntfMemBlk.sv $(XSSV_HOME)/rtl/dft/MbistPipeMemBlk.sv $(XSSV_HOME)/rtl/dft/MbistPipeSms.sv \
              $(XSSV_HOME)/rtl/backend/MemExeUnit.sv $(XSSV_HOME)/rtl/uncore/NewPipelineConnectPipe_34.sv $(XSSV_HOME)/rtl/uncore/NewPipelineConnectPipe_35.sv \
              $(XSSV_HOME)/rtl/backend/PFEvent.sv $(XSSV_HOME)/rtl/memblock/Pipeline.sv $(XSSV_HOME)/rtl/memblock/PipelineRegModule.sv \
              $(XSSV_HOME)/rtl/memblock/PipelineRegModule_6.sv $(XSSV_HOME)/rtl/memblock/PMP.sv $(XSSV_HOME)/rtl/backend/PMPChecker_12.sv \
              $(XSSV_HOME)/rtl/memblock/PTWNewFilter.sv $(XSSV_HOME)/rtl/mmu/PTWRepeaterNB.sv $(XSSV_HOME)/rtl/memblock/Sbuffer.sv \
              $(XSSV_HOME)/rtl/memblock/SMSPrefetcher.sv $(XSSV_HOME)/rtl/memblock/StoreMisalignBuffer.sv $(XSSV_HOME)/rtl/memblock/StoreUnit.sv \
              $(XSSV_HOME)/rtl/memblock/TLBNonBlock.sv $(XSSV_HOME)/rtl/memblock/TLBNonBlock_1.sv $(XSSV_HOME)/rtl/memblock/TLBNonBlock_2.sv \
              $(XSSV_HOME)/rtl/memblock/TLBuffer_6.sv $(XSSV_HOME)/rtl/memblock/TLBuffer_7.sv $(XSSV_HOME)/rtl/memblock/TLBuffer_8.sv \
              $(XSSV_HOME)/rtl/memblock/TLBuffer_9.sv $(XSSV_HOME)/rtl/uncore/TLXbar_4.sv $(XSSV_HOME)/rtl/memblock/Uncache.sv \
              $(XSSV_HOME)/rtl/memblock/VfofBuffer.sv $(XSSV_HOME)/rtl/memblock/VLMergeBufferImp.sv $(XSSV_HOME)/rtl/memblock/VLSplitImp.sv \
              $(XSSV_HOME)/rtl/memblock/VSegmentUnit.sv $(XSSV_HOME)/rtl/memblock/VSMergeBufferImp.sv $(XSSV_HOME)/rtl/memblock/VSSplitImp.sv \
              $(XSSV_HOME)/rtl/memblock/MemBlock.sv
fm-MemBlock: RTL_SRCS = $(FM_IMPL_RTL)
fm-MemBlock: RTL_GOLDEN_DEPS =
FM_INTERFACE_ONLY = AtomicsUnit DCacheWrapper DelayN_331 DelayN_333 DelayN_8 DelayNWithValid_2 DelayNWithValid_200 DelayNWithValid_202 DelayNWithValid_203 DelayNWithValid_3 FrontendBridge HPerfMonitor_3 L1Prefetcher L2TLBWrapper LoadMisalignBuffer LoadUnit LsqWrapper MbistIntfMemBlk MbistPipeMemBlk MbistPipeSms MemExeUnit NewPipelineConnectPipe_34 NewPipelineConnectPipe_35 PFEvent Pipeline PipelineRegModule PipelineRegModule_6 PMP PMPChecker_12 PTWNewFilter PTWRepeaterNB Sbuffer SMSPrefetcher StoreMisalignBuffer StoreUnit TLBNonBlock TLBNonBlock_1 TLBNonBlock_2 TLBuffer_6 TLBuffer_7 TLBuffer_8 TLBuffer_9 TLXbar_4 Uncache VfofBuffer VLMergeBufferImp VLSplitImp VSegmentUnit VSMergeBufferImp VSSplitImp
FM_MODE = assembly
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位 + 黑盒输入位，fm_predict 模型严格适用。
FM_MERGE_DUP = false
# 两侧对称死位真比；依据与六条见 verif/fm_target_config/MemBlock.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2 等，两侧统一定义 SYNTHESIS。
# 初值档（编译期打开机制，运行期选档）：INITREG=0 / 1 —— 全设计常量初值。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
ifneq ($(filter $(INITREG),0 1),$(INITREG))
$(error INITREG 只认 0 / 1)
endif
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck gentb
gencheck:
	python3 ../../../scripts/gen_memblock.py --check
	python3 gen.py --check
gentb:
	python3 gen.py
