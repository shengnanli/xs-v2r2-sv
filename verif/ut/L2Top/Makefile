MODULE = L2Top

# L2Top：香山 Tile 里 L2 那一层的装配壳（src/main/scala/xiangshan/L2Top.scala）。
# impl = rtl/l2/L2Top.sv（手写核 xs_L2Top_core + scripts/gen_l2top.py 生成的 golden 同名 wrapper，21 个 child 实例名同 golden）。
# FM（codex 0217 层次化组合）：inner_l2cache（TL2CHICoupledL2）是 green_child —— 两侧都不给源，allow 绑定其 tracked 证书 sha；
# L2Top 本层 glue 与其余 child 两侧白盒受验（ref 读 G1，impl 读本仓重写件，见 FM_IMPL_RTL）。两侧共读同一份 G1 的只有
# Queue2_TLBundle* 里的 MC 存储模型 ram_2x*/ram_sink_2x8（verif/mc_memory_registry.tsv 已逐条登记 MC_MEMORY_MODEL）。
# UT（VCS）仍跑整棵树：RTL_SRCS / GOLDEN_SRCS 是全集，SHARED_GOLDEN 是 UT 两侧共用的行为模型。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/uncore_common_pkg.sv $(RTL_DIR)/l2/L2Top.sv \
           $(RTL_DIR)/common/DelayNWithValid_203.sv $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayN_334.sv $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_22.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv $(RTL_DIR)/memblock/TLBuffer_20.sv \
           $(RTL_DIR)/memblock/TLBuffer_8.sv \
           \
           $(RTL_DIR)/memblock/TLBuffer_15.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_13.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_12.sv $(RTL_DIR)/uncore/TL2CHICoupledL2.sv \
           $(RTL_DIR)/uncore/Pipeline_13.sv $(RTL_DIR)/uncore/Queue1_CHIRSP.sv \
           $(RTL_DIR)/common/xs_ChiselQueue1_core.sv $(RTL_DIR)/uncore/Pipeline_12.sv \
           $(RTL_DIR)/uncore/Queue1_CHIDAT.sv $(RTL_DIR)/uncore/LinkMonitor.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled_2.sv $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled.sv $(RTL_DIR)/uncore/Queue4_CHISNP.sv \
           $(RTL_DIR)/uncore/xs_ChiselQueuePipe_core.sv $(RTL_DIR)/uncore/Decoupled2LCredit_2.sv \
           $(RTL_DIR)/uncore/Decoupled2LCredit_1.sv $(RTL_DIR)/uncore/Decoupled2LCredit.sv \
           $(RTL_DIR)/uncore/FastArbiter_28.sv $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/Queue2_PCrdGranted.sv $(RTL_DIR)/uncore/Queue78_PCrdGranted.sv \
           $(RTL_DIR)/uncore/FastArbiter_27.sv $(RTL_DIR)/uncore/FastArbiter_26.sv \
           $(RTL_DIR)/common/RRArbiterInit_20.sv $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/dft/MbistIntfL2.sv $(RTL_DIR)/dft/L2Cache.sv $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/uncore/Pipeline_11.sv $(RTL_DIR)/frontend/Queue1_UInt32.sv \
           $(RTL_DIR)/uncore/Pipeline_10.sv $(RTL_DIR)/l2/TopDownMonitor.sv \
           $(RTL_DIR)/frontend/Arbiter4_L2ToL1Hint.sv $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/l2/Arbiter4_L2CacheErrorInfo.sv $(RTL_DIR)/uncore/Pipeline_3.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchResp.sv $(RTL_DIR)/uncore/Pipeline_2.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchTrain.sv $(RTL_DIR)/uncore/Slice_3.sv \
           $(RTL_DIR)/dft/L2Slice_3.sv $(RTL_DIR)/uncore/DataStorage_3.sv $(RTL_DIR)/dft/L2DataStorage_3.sv \
           $(RTL_DIR)/dft/xs_mbist_hold_leaf_core.sv $(RTL_DIR)/uncore/GatedSplittedSRAM_3.sv \
           $(RTL_DIR)/common/MbistClockGateCell_93.sv $(RTL_DIR)/common/ClockMux.sv \
           $(RTL_DIR)/common/SRAMTemplate_178.sv $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/MbistClockGateCell.sv $(RTL_DIR)/uncore/xs_DataStorage_core.sv \
           $(RTL_DIR)/uncore/Directory_3.sv $(RTL_DIR)/dft/L2Directory_3.sv \
           $(RTL_DIR)/common/SRAMTemplate_187.sv $(RTL_DIR)/common/SRAMTemplate_186.sv \
           $(RTL_DIR)/common/SRAMTemplate_185.sv $(RTL_DIR)/uncore/SplittedSRAM_6.sv \
           $(RTL_DIR)/common/SRAMTemplate_181.sv $(RTL_DIR)/uncore/xs_Directory_core.sv \
           $(RTL_DIR)/uncore/Slice.sv $(RTL_DIR)/uncore/MSHRCtl.sv $(RTL_DIR)/uncore/MSHRSelector.sv \
           $(RTL_DIR)/uncore/SourceB.sv $(RTL_DIR)/uncore/FastArbiter_5.sv $(RTL_DIR)/uncore/FastArbiter_7.sv \
           $(RTL_DIR)/uncore/FastArbiter_6.sv $(RTL_DIR)/uncore/FastArbiter_4.sv \
           $(RTL_DIR)/uncore/FastArbiter_3.sv $(RTL_DIR)/uncore/MSHR.sv $(RTL_DIR)/uncore/RequestBuffer.sv \
           $(RTL_DIR)/uncore/Queue1_ChosenQBundle.sv $(RTL_DIR)/uncore/FastArbiter_2.sv \
           $(RTL_DIR)/uncore/MainPipe_1.sv $(RTL_DIR)/uncore/Arbiter3_TaskBundle.sv \
           $(RTL_DIR)/uncore/Arbiter3_CHIREQ.sv $(RTL_DIR)/uncore/Arbiter3_TaskWithData.sv \
           $(RTL_DIR)/uncore/CustomL1Hint.sv $(RTL_DIR)/uncore/Queue4_HintQueueEntry.sv \
           $(RTL_DIR)/uncore/Queue16_HintQueueEntry.sv $(RTL_DIR)/uncore/RequestArb.sv \
           $(RTL_DIR)/uncore/MSHRBuffer_1.sv $(RTL_DIR)/uncore/MSHRBuffer.sv $(RTL_DIR)/uncore/RXRSP.sv \
           $(RTL_DIR)/uncore/RXDAT.sv $(RTL_DIR)/uncore/RXSNP.sv $(RTL_DIR)/uncore/Queue2_CHISNP.sv \
           $(RTL_DIR)/uncore/TXRSP.sv $(RTL_DIR)/uncore/TXDAT.sv \
           $(RTL_DIR)/uncore/Queue16_DSBeat.sv $(RTL_DIR)/uncore/Queue16_TaskBundle.sv \
           $(RTL_DIR)/uncore/TXREQ.sv $(RTL_DIR)/uncore/GrantBuffer.sv \
           $(RTL_DIR)/uncore/Queue10_GrantBuffer_Anon.sv $(RTL_DIR)/uncore/Queue16_GrantQueueData.sv \
           $(RTL_DIR)/uncore/Queue16_GrantQueueTask.sv $(RTL_DIR)/uncore/SinkC.sv \
           $(RTL_DIR)/common/RRArbiterInit_16.sv $(RTL_DIR)/uncore/SinkA.sv $(RTL_DIR)/uncore/Slice_2.sv \
           $(RTL_DIR)/dft/L2Slice_2.sv $(RTL_DIR)/uncore/DataStorage_2.sv $(RTL_DIR)/dft/L2DataStorage_2.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM_2.sv $(RTL_DIR)/common/SRAMTemplate_166.sv \
           $(RTL_DIR)/uncore/Directory_2.sv $(RTL_DIR)/dft/L2Directory_2.sv \
           $(RTL_DIR)/common/SRAMTemplate_165.sv $(RTL_DIR)/common/SRAMTemplate_164.sv \
           $(RTL_DIR)/common/SRAMTemplate_163.sv $(RTL_DIR)/uncore/SplittedSRAM_5.sv \
           $(RTL_DIR)/common/SRAMTemplate_162.sv $(RTL_DIR)/uncore/Slice_1.sv $(RTL_DIR)/dft/L2Slice_1.sv \
           $(RTL_DIR)/uncore/DataStorage_1.sv $(RTL_DIR)/dft/L2DataStorage_1.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM_1.sv $(RTL_DIR)/uncore/Directory_1.sv \
           $(RTL_DIR)/dft/L2Directory_1.sv $(RTL_DIR)/uncore/SplittedSRAM_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_159.sv $(RTL_DIR)/dft/L2Slice.sv $(RTL_DIR)/uncore/DataStorage.sv \
           $(RTL_DIR)/dft/L2DataStorage.sv $(RTL_DIR)/uncore/GatedSplittedSRAM.sv \
           $(RTL_DIR)/common/SRAMTemplate_155.sv $(RTL_DIR)/uncore/Directory.sv \
           $(RTL_DIR)/uncore/L2Directory.sv $(RTL_DIR)/common/SRAMTemplate_154.sv \
           $(RTL_DIR)/common/SRAMTemplate_153.sv $(RTL_DIR)/common/SRAMTemplate_152.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_3.sv $(RTL_DIR)/common/SRAMTemplate_150.sv \
           $(RTL_DIR)/common/SRAMTemplate_148.sv $(RTL_DIR)/uncore/FastArbiter_1.sv \
           $(RTL_DIR)/uncore/FastArbiter.sv $(RTL_DIR)/l2/Prefetcher.sv $(RTL_DIR)/uncore/Pipeline_1.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchReq.sv $(RTL_DIR)/l2/PrefetchQueue.sv \
           $(RTL_DIR)/frontend/Arbiter4_PrefetchReq.sv $(RTL_DIR)/dft/MbistPipeL2Prefetcher.sv \
           $(RTL_DIR)/l2/PrefetchReceiver.sv $(RTL_DIR)/l2/VBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/PrefetchReqBuffer.sv $(RTL_DIR)/common/RRArbiterInit_15.sv \
           $(RTL_DIR)/common/RRArbiterInit_14.sv $(RTL_DIR)/l2/OffsetScoreTable_1.sv \
           $(RTL_DIR)/l2/xs_OffsetScoreTable_core.sv $(RTL_DIR)/uncore/RecentRequestTable_1.sv \
           $(RTL_DIR)/uncore/RecentRequestTable.sv $(RTL_DIR)/common/SRAMTemplate_146.sv \
           $(RTL_DIR)/l2/DelayQueue_1.sv $(RTL_DIR)/l2/xs_DelayQueue_core.sv \
           $(RTL_DIR)/l2/PBestOffsetPrefetch.sv $(RTL_DIR)/l2/OffsetScoreTable.sv $(RTL_DIR)/l2/DelayQueue.sv \
           $(RTL_DIR)/uncore/MMIOBridge.sv $(RTL_DIR)/uncore/Arbiter16_TLBundleD.sv \
           $(RTL_DIR)/uncore/Arbiter16_CHIDAT.sv $(RTL_DIR)/common/RRArbiterInit_13.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry_8.sv $(RTL_DIR)/uncore/xs_MMIOBridgeEntry_core.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry_4.sv $(RTL_DIR)/uncore/MMIOBridgeEntry_2.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry.sv $(RTL_DIR)/backend/IntBuffer.sv \
           $(RTL_DIR)/memblock/TLBuffer_6.sv \
           $(RTL_DIR)/uncore/TLLogger_2.sv \
           $(RTL_DIR)/uncore/TLLogger_1.sv $(RTL_DIR)/uncore/TLLogger.sv $(RTL_DIR)/memblock/TLBuffer_13.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleE_1.sv $(RTL_DIR)/uncore/Queue2_TLBundleC_1.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleB_1.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_20.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_19.sv $(RTL_DIR)/uncore/BusPerfMonitor.sv \
           $(RTL_DIR)/l2/BusErrorUnit.sv $(RTL_DIR)/uncore/TLXbar_6.sv \
           $(RTL_DIR)/common/xs_TLArbiterRoundRobin.sv $(RTL_DIR)/uncore/TLXbar_5.sv \
           $(RTL_DIR)/uncore/Queue16_CHIREQ.sv $(RTL_DIR)/uncore/Queue16_CHIRSP.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_10.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_11.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_31.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_6.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_7.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_14.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_15.sv

SHARED_GOLDEN = \
                array_13.sv array_14.sv array_15.sv array_16.sv array_17.sv array_18.sv ram_16x11.sv \
                ram_16x137.sv ram_16x25.sv ram_16x62.sv ram_16x67.sv ram_2x117.sv ram_2x119.sv ram_2x133.sv \
                ram_2x136.sv ram_2x137.sv ram_2x15.sv ram_2x281.sv ram_2x283.sv ram_2x321.sv ram_2x352.sv \
                ram_2x356.sv ram_2x76.sv ram_2x79.sv ram_2x80.sv ram_2x98.sv ram_4x11.sv ram_4x115.sv \
                ram_data_16x256.sv ram_sink_2x8.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                sram_array_1p4096x137m137s1h1l2b_l2_dat.sv sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
                sram_array_1p512x16m16s1h0l1b_l2_repl.sv sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
                sram_array_1p512x8m1s1h0l1b_l2_orgb.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SHARED_GOLDEN)) $(XSSV_HOME)/rtl/common/ClockGate.sv
# 厂商 SRAM 叶子：UT 两侧共用（仿真需要行为），FM 两侧都不给（对称黑盒）
VENDOR_EXT = array_13_ext.v array_14_ext.v array_15_ext.v array_16_ext.v array_17_ext.v array_18_ext.v
# 授权父级不含本目标的两个 ram 模型：UT 两侧共用 golden 行为，FM 两侧都不给
BB_RAM = ram_10x89.sv ram_78x15.sv
TB_SRCS  = tb.sv

# golden 闭包（FM ref 侧，字面文件名；不含 BB_RAM 与 VENDOR_EXT）
# golden 闭包（FM ref 侧，字面文件名）—— codex 0217 层次化组合：inner_l2cache（TL2CHICoupledL2）是 green_child，
# 两侧都不给源（对称未解析黑盒，verif/allow/L2Top.json 绑定 TL2CHICoupledL2 证书 sha）；这里只剩 L2Top 本层 glue 例化到的模块。
FM_REF_DEPS_L2Top = BusErrorUnit.sv BusPerfMonitor.sv DelayNWithValid_203.sv DelayN_334.sv IntBuffer.sv \
                    Queue2_TLBundleA_10.sv Queue2_TLBundleA_12.sv Queue2_TLBundleA_14.sv \
                    Queue2_TLBundleA_19.sv Queue2_TLBundleA_31.sv Queue2_TLBundleA_6.sv Queue2_TLBundleB_1.sv \
                    Queue2_TLBundleC_1.sv Queue2_TLBundleD_11.sv Queue2_TLBundleD_13.sv Queue2_TLBundleD_15.sv \
                    Queue2_TLBundleD_20.sv Queue2_TLBundleD_7.sv Queue2_TLBundleE_1.sv TLBuffer_13.sv \
                    TLBuffer_15.sv TLBuffer_20.sv TLBuffer_22.sv TLBuffer_6.sv TLBuffer_8.sv TLLogger.sv \
                    TLLogger_1.sv TLLogger_2.sv TLXbar_5.sv TLXbar_6.sv ram_2x117.sv ram_2x119.sv ram_2x133.sv \
                    ram_2x136.sv ram_2x137.sv ram_2x281.sv ram_2x283.sv ram_2x321.sv ram_2x352.sv ram_2x356.sv \
                    ram_2x76.sv ram_2x79.sv ram_2x80.sv ram_sink_2x8.sv
# UT（VCS）仍要整棵树：green_child 子树的 golden 文件只进仿真，不进 FM。
UT_GOLDEN_CHILD_DEPS = Arbiter16_CHIDAT.sv Arbiter16_TLBundleD.sv Arbiter3_CHIREQ.sv Arbiter3_TaskBundle.sv \
                       Arbiter3_TaskWithData.sv Arbiter4_L2CacheErrorInfo.sv Arbiter4_L2ToL1Hint.sv \
                       Arbiter4_PrefetchReq.sv ClockGate.sv ClockMux.sv CustomL1Hint.sv DataStorage.sv \
                       DataStorage_1.sv DataStorage_2.sv DataStorage_3.sv Decoupled2LCredit.sv \
                       Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv DelayQueue.sv DelayQueue_1.sv \
                       Directory.sv Directory_1.sv Directory_2.sv Directory_3.sv FastArbiter.sv \
                       FastArbiter_1.sv FastArbiter_2.sv FastArbiter_26.sv FastArbiter_27.sv FastArbiter_28.sv \
                       FastArbiter_3.sv FastArbiter_4.sv FastArbiter_5.sv FastArbiter_6.sv FastArbiter_7.sv \
                       GatedSplittedSRAM.sv GatedSplittedSRAM_1.sv GatedSplittedSRAM_2.sv \
                       GatedSplittedSRAM_3.sv GrantBuffer.sv L2Cache.sv L2DataStorage.sv L2DataStorage_1.sv \
                       L2DataStorage_2.sv L2DataStorage_3.sv L2Directory.sv L2Directory_1.sv L2Directory_2.sv \
                       L2Directory_3.sv L2Slice.sv L2Slice_1.sv L2Slice_2.sv L2Slice_3.sv LCredit2Decoupled.sv \
                       LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv LinkMonitor.sv MMIOBridge.sv \
                       MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv MMIOBridgeEntry_8.sv \
                       MSHR.sv MSHRBuffer.sv MSHRBuffer_1.sv MSHRCtl.sv MSHRSelector.sv MainPipe_1.sv \
                       MbistClockGateCell_93.sv MbistIntfL2.sv MbistPipeL2Prefetcher.sv OffsetScoreTable.sv \
                       OffsetScoreTable_1.sv PBestOffsetPrefetch.sv Pipeline_1.sv Pipeline_10.sv \
                       Pipeline_11.sv Pipeline_12.sv Pipeline_13.sv Pipeline_2.sv Pipeline_3.sv \
                       PrefetchQueue.sv PrefetchReceiver.sv PrefetchReqBuffer.sv Prefetcher.sv \
                       Queue10_GrantBuffer_Anon.sv Queue16_CHIREQ.sv Queue16_CHIRSP.sv Queue16_DSBeat.sv \
                       Queue16_GrantQueueData.sv Queue16_GrantQueueTask.sv Queue16_HintQueueEntry.sv \
                       Queue16_TaskBundle.sv Queue1_CHIDAT.sv Queue1_CHIRSP.sv Queue1_ChosenQBundle.sv \
                       Queue1_PrefetchReq.sv Queue1_PrefetchResp.sv Queue1_PrefetchTrain.sv Queue1_UInt32.sv \
                       Queue2_CHISNP.sv Queue2_PCrdGranted.sv Queue4_CHISNP.sv Queue4_HintQueueEntry.sv \
                       Queue78_PCrdGranted.sv RRArbiterInit_13.sv RRArbiterInit_14.sv RRArbiterInit_15.sv \
                       RRArbiterInit_16.sv RRArbiterInit_20.sv RXDAT.sv RXRSP.sv RXSNP.sv \
                       RecentRequestTable.sv RecentRequestTable_1.sv RequestArb.sv RequestBuffer.sv \
                       SRAMTemplate_146.sv SRAMTemplate_148.sv SRAMTemplate_150.sv SRAMTemplate_152.sv \
                       SRAMTemplate_153.sv SRAMTemplate_154.sv SRAMTemplate_155.sv SRAMTemplate_159.sv \
                       SRAMTemplate_162.sv SRAMTemplate_163.sv SRAMTemplate_164.sv SRAMTemplate_165.sv \
                       SRAMTemplate_166.sv SRAMTemplate_178.sv SRAMTemplate_181.sv SRAMTemplate_185.sv \
                       SRAMTemplate_186.sv SRAMTemplate_187.sv SinkA.sv SinkC.sv Slice.sv Slice_1.sv \
                       Slice_2.sv Slice_3.sv SourceB.sv SplittedSRAM_3.sv SplittedSRAM_4.sv SplittedSRAM_5.sv \
                       SplittedSRAM_6.sv TL2CHICoupledL2.sv TXDAT.sv TXREQ.sv TXRSP.sv TopDownMonitor.sv \
                       VBestOffsetPrefetch.sv array_13.sv array_14.sv array_15.sv array_16.sv array_17.sv \
                       array_18.sv ram_16x11.sv ram_16x137.sv ram_16x25.sv ram_16x62.sv ram_16x67.sv \
                       ram_2x15.sv ram_2x98.sv ram_4x11.sv ram_4x115.sv ram_data_16x256.sv \
                       sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                       sram_array_1p4096x137m137s1h1l2b_l2_dat.sv sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
                       sram_array_1p512x16m16s1h0l1b_l2_repl.sv sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
                       sram_array_1p512x8m1s1h0l1b_l2_orgb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,L2Top.sv $(FM_REF_DEPS_L2Top) $(UT_GOLDEN_CHILD_DEPS) $(BB_RAM) $(VENDOR_EXT))
FM_VARIANTS = L2Top
FM_MERGE_DUP = false
FM_MODE = assembly
FM_ALLOWLIST ?= 0
# FM impl 侧（codex 0217）：只给 L2Top 本层 glue 例化到的重写件；inner_l2cache 子树不给（= 对称黑盒）。
# UT 的 RTL_SRCS 仍是全集（derive / VCS 用），这里只对 fm-L2Top 做 target-specific 覆盖。
FM_IMPL_RTL = $(RTL_DIR)/l2/L2Top.sv $(RTL_DIR)/common/DelayNWithValid_203.sv \
              $(RTL_DIR)/common/xs_DelayNWithValid_core.sv $(RTL_DIR)/common/DelayN_334.sv \
              $(RTL_DIR)/common/xs_DelayN_core.sv $(RTL_DIR)/memblock/TLBuffer_22.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleD_11.sv $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleA_31.sv $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
              $(RTL_DIR)/memblock/TLBuffer_20.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_10.sv \
              $(RTL_DIR)/memblock/TLBuffer_8.sv $(RTL_DIR)/uncore/Queue2_TLBundleD_15.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleA_14.sv $(RTL_DIR)/memblock/TLBuffer_15.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleD_13.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_12.sv \
              $(RTL_DIR)/backend/IntBuffer.sv $(RTL_DIR)/memblock/TLBuffer_6.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleD_7.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_6.sv \
              $(RTL_DIR)/uncore/TLLogger_2.sv $(RTL_DIR)/uncore/TLLogger_1.sv $(RTL_DIR)/uncore/TLLogger.sv \
              $(RTL_DIR)/memblock/TLBuffer_13.sv $(RTL_DIR)/uncore/Queue2_TLBundleE_1.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleC_1.sv $(RTL_DIR)/uncore/Queue2_TLBundleB_1.sv \
              $(RTL_DIR)/uncore/Queue2_TLBundleD_20.sv $(RTL_DIR)/uncore/Queue2_TLBundleA_19.sv \
              $(RTL_DIR)/uncore/BusPerfMonitor.sv $(RTL_DIR)/l2/BusErrorUnit.sv $(RTL_DIR)/uncore/TLXbar_6.sv \
              $(RTL_DIR)/common/xs_TLArbiterRoundRobin.sv $(RTL_DIR)/uncore/TLXbar_5.sv
fm-L2Top: RTL_SRCS = $(FM_IMPL_RTL)
fm-L2Top: RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,ram_2x117.sv ram_2x119.sv ram_2x133.sv ram_2x136.sv ram_2x137.sv ram_2x281.sv ram_2x283.sv ram_2x321.sv ram_2x352.sv ram_2x356.sv ram_2x76.sv ram_2x79.sv ram_2x80.sv ram_sink_2x8.sv)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
# RANDOMIZE_MEM_INIT：只影响厂商 SRAM 叶子 array_*_ext 的存储体初值（同 verif/ut/Slice）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +define+RANDOMIZE_MEM_INIT +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen_tb.py
gencheck:
	python3 gen_tb.py --check
	python3 ../../../scripts/gen_l2top.py --check
