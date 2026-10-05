MODULE = TL2CHICoupledL2

# TL2CHICoupledL2：香山 L2 Cache 顶层（coupledL2 tl2chi/TL2CHICoupledL2.scala + CoupledL2.scala）。
# impl = rtl/uncore/TL2CHICoupledL2.sv（手写胶合核 xs_TL2CHICoupledL2_core + scripts/gen_tl2chi.py 生成的 golden 同名
#        wrapper，32 个 child 实例名同 golden）。
# child 全部 PROVEN_DIRECT，两侧白盒：ref 读 golden，impl 读本仓重写件（闭包见 RTL_SRCS，按 impl 侧例化关系
# 从 rtl/ 现找，一模块一文件）。两侧共读同一份 golden 的（SHARED_GOLDEN）：行为级存储模型（ram_* / sram_array_* / array_N）、
# 本地重写的 ClockGate（codex 0208）。Queue16_CHIREQ/CHIRSP 是普通队列逻辑：impl 读本仓已签重写件、ref 读 G1
# （与 Slice 一致，codex 0219 §3.2）。
# FM 两侧都不给（= 对称黑盒）的：厂商 SRAM 叶子 array_13..18_ext（vendor_boundary 已审定），以及
#   ram_10x89（4 个 Slice 的 GrantBuffer.pftRespQueue）/ ram_78x15（pCrdQueue_s2）——这两个 APPROVED_MEMORY_MACRO_MODEL
#   的授权父级目前不含 TL2CHICoupledL2（codex 0202/0206/0210），**本目标的正式 FM 待 codex 扩授权后再跑**。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/uncore_common_pkg.sv $(RTL_DIR)/uncore/TL2CHICoupledL2.sv \
           $(RTL_DIR)/uncore/Pipeline_13.sv $(RTL_DIR)/uncore/Queue1_CHIRSP.sv \
           $(RTL_DIR)/common/xs_ChiselQueue1_core.sv $(RTL_DIR)/uncore/Pipeline_12.sv \
           $(RTL_DIR)/uncore/Queue1_CHIDAT.sv $(RTL_DIR)/uncore/LinkMonitor.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled_2.sv $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled.sv $(RTL_DIR)/uncore/Queue4_CHISNP.sv \
           $(RTL_DIR)/uncore/xs_ChiselQueuePipe_core.sv $(RTL_DIR)/uncore/Decoupled2LCredit_2.sv \
           $(RTL_DIR)/uncore/Decoupled2LCredit_1.sv $(RTL_DIR)/uncore/Decoupled2LCredit.sv \
           $(RTL_DIR)/uncore/FastArbiter_28.sv $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/Queue2_PCrdGranted.sv $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue78_PCrdGranted.sv $(RTL_DIR)/uncore/FastArbiter_27.sv \
           $(RTL_DIR)/uncore/FastArbiter_26.sv $(RTL_DIR)/common/RRArbiterInit_20.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv $(RTL_DIR)/dft/MbistIntfL2.sv $(RTL_DIR)/dft/L2Cache.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv $(RTL_DIR)/uncore/Pipeline_11.sv \
           $(RTL_DIR)/frontend/Queue1_UInt32.sv $(RTL_DIR)/uncore/Pipeline_10.sv \
           $(RTL_DIR)/l2/TopDownMonitor.sv $(RTL_DIR)/frontend/Arbiter4_L2ToL1Hint.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv $(RTL_DIR)/l2/Arbiter4_L2CacheErrorInfo.sv \
           $(RTL_DIR)/uncore/Pipeline_3.sv $(RTL_DIR)/frontend/Queue1_PrefetchResp.sv \
           $(RTL_DIR)/uncore/Pipeline_2.sv $(RTL_DIR)/frontend/Queue1_PrefetchTrain.sv \
           $(RTL_DIR)/uncore/Slice_3.sv $(RTL_DIR)/dft/L2Slice_3.sv $(RTL_DIR)/uncore/DataStorage_3.sv \
           $(RTL_DIR)/dft/L2DataStorage_3.sv $(RTL_DIR)/dft/xs_mbist_hold_leaf_core.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM_3.sv $(RTL_DIR)/common/MbistClockGateCell_93.sv \
           $(RTL_DIR)/common/ClockMux.sv $(RTL_DIR)/common/SRAMTemplate_178.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv $(RTL_DIR)/common/MbistClockGateCell.sv \
           $(RTL_DIR)/uncore/xs_DataStorage_core.sv $(RTL_DIR)/uncore/Directory_3.sv \
           $(RTL_DIR)/dft/L2Directory_3.sv $(RTL_DIR)/common/SRAMTemplate_187.sv \
           $(RTL_DIR)/common/SRAMTemplate_186.sv $(RTL_DIR)/common/SRAMTemplate_185.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_6.sv $(RTL_DIR)/common/SRAMTemplate_181.sv \
           $(RTL_DIR)/uncore/xs_Directory_core.sv $(RTL_DIR)/uncore/Slice.sv $(RTL_DIR)/uncore/MSHRCtl.sv \
           $(RTL_DIR)/uncore/MSHRSelector.sv $(RTL_DIR)/uncore/SourceB.sv $(RTL_DIR)/uncore/FastArbiter_5.sv \
           $(RTL_DIR)/uncore/FastArbiter_7.sv $(RTL_DIR)/uncore/FastArbiter_6.sv \
           $(RTL_DIR)/uncore/FastArbiter_4.sv $(RTL_DIR)/uncore/FastArbiter_3.sv $(RTL_DIR)/uncore/MSHR.sv \
           $(RTL_DIR)/uncore/RequestBuffer.sv $(RTL_DIR)/uncore/Queue1_ChosenQBundle.sv \
           $(RTL_DIR)/uncore/FastArbiter_2.sv $(RTL_DIR)/uncore/MainPipe_1.sv \
           $(RTL_DIR)/uncore/Arbiter3_TaskBundle.sv $(RTL_DIR)/uncore/Arbiter3_CHIREQ.sv \
           $(RTL_DIR)/uncore/Arbiter3_TaskWithData.sv $(RTL_DIR)/uncore/CustomL1Hint.sv \
           $(RTL_DIR)/uncore/Queue4_HintQueueEntry.sv $(RTL_DIR)/uncore/Queue16_HintQueueEntry.sv \
           $(RTL_DIR)/uncore/RequestArb.sv $(RTL_DIR)/uncore/MSHRBuffer_1.sv $(RTL_DIR)/uncore/MSHRBuffer.sv \
           $(RTL_DIR)/uncore/RXRSP.sv $(RTL_DIR)/uncore/RXDAT.sv $(RTL_DIR)/uncore/RXSNP.sv \
           $(RTL_DIR)/uncore/Queue2_CHISNP.sv $(RTL_DIR)/uncore/TXRSP.sv \
           $(RTL_DIR)/uncore/TXDAT.sv $(RTL_DIR)/uncore/Queue16_DSBeat.sv \
           $(RTL_DIR)/uncore/Queue16_TaskBundle.sv $(RTL_DIR)/uncore/TXREQ.sv \
           $(RTL_DIR)/uncore/GrantBuffer.sv \
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
           $(RTL_DIR)/uncore/MMIOBridgeEntry.sv \
           $(RTL_DIR)/uncore/Queue16_CHIREQ.sv $(RTL_DIR)/uncore/Queue16_CHIRSP.sv

SHARED_GOLDEN = \
                array_13.sv array_14.sv array_15.sv array_16.sv array_17.sv array_18.sv ram_16x11.sv \
                ram_16x137.sv ram_16x25.sv ram_16x62.sv ram_16x67.sv ram_2x15.sv ram_2x98.sv ram_4x11.sv \
                ram_4x115.sv ram_data_16x256.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
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
FM_REF_DEPS_TL2CHICoupledL2 = Arbiter16_CHIDAT.sv Arbiter16_TLBundleD.sv Arbiter3_CHIREQ.sv \
                              Arbiter3_TaskBundle.sv Arbiter3_TaskWithData.sv Arbiter4_L2CacheErrorInfo.sv \
                              Arbiter4_L2ToL1Hint.sv Arbiter4_PrefetchReq.sv ClockGate.sv ClockMux.sv \
                              CustomL1Hint.sv DataStorage.sv DataStorage_1.sv DataStorage_2.sv \
                              DataStorage_3.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv \
                              Decoupled2LCredit_2.sv DelayQueue.sv DelayQueue_1.sv Directory.sv Directory_1.sv \
                              Directory_2.sv Directory_3.sv FastArbiter.sv FastArbiter_1.sv FastArbiter_2.sv \
                              FastArbiter_26.sv FastArbiter_27.sv FastArbiter_28.sv FastArbiter_3.sv \
                              FastArbiter_4.sv FastArbiter_5.sv FastArbiter_6.sv FastArbiter_7.sv \
                              GatedSplittedSRAM.sv GatedSplittedSRAM_1.sv GatedSplittedSRAM_2.sv \
                              GatedSplittedSRAM_3.sv GrantBuffer.sv L2Cache.sv L2DataStorage.sv \
                              L2DataStorage_1.sv L2DataStorage_2.sv L2DataStorage_3.sv L2Directory.sv \
                              L2Directory_1.sv L2Directory_2.sv L2Directory_3.sv L2Slice.sv L2Slice_1.sv \
                              L2Slice_2.sv L2Slice_3.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv \
                              LCredit2Decoupled_2.sv LinkMonitor.sv MMIOBridge.sv MMIOBridgeEntry.sv \
                              MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv MMIOBridgeEntry_8.sv MSHR.sv \
                              MSHRBuffer.sv MSHRBuffer_1.sv MSHRCtl.sv MSHRSelector.sv MainPipe_1.sv \
                              MbistClockGateCell_93.sv MbistIntfL2.sv MbistPipeL2Prefetcher.sv \
                              OffsetScoreTable.sv OffsetScoreTable_1.sv PBestOffsetPrefetch.sv Pipeline_1.sv \
                              Pipeline_10.sv Pipeline_11.sv Pipeline_12.sv Pipeline_13.sv Pipeline_2.sv \
                              Pipeline_3.sv PrefetchQueue.sv PrefetchReceiver.sv PrefetchReqBuffer.sv \
                              Prefetcher.sv Queue10_GrantBuffer_Anon.sv Queue16_CHIREQ.sv Queue16_CHIRSP.sv \
                              Queue16_DSBeat.sv Queue16_GrantQueueData.sv Queue16_GrantQueueTask.sv \
                              Queue16_HintQueueEntry.sv Queue16_TaskBundle.sv Queue1_CHIDAT.sv \
                              Queue1_CHIRSP.sv Queue1_ChosenQBundle.sv Queue1_PrefetchReq.sv \
                              Queue1_PrefetchResp.sv Queue1_PrefetchTrain.sv Queue1_UInt32.sv Queue2_CHISNP.sv \
                              Queue2_PCrdGranted.sv Queue4_CHISNP.sv Queue4_HintQueueEntry.sv \
                              Queue78_PCrdGranted.sv RRArbiterInit_13.sv RRArbiterInit_14.sv \
                              RRArbiterInit_15.sv RRArbiterInit_16.sv RRArbiterInit_20.sv RXDAT.sv RXRSP.sv \
                              RXSNP.sv RecentRequestTable.sv RecentRequestTable_1.sv RequestArb.sv \
                              RequestBuffer.sv SRAMTemplate_146.sv SRAMTemplate_148.sv SRAMTemplate_150.sv \
                              SRAMTemplate_152.sv SRAMTemplate_153.sv SRAMTemplate_154.sv SRAMTemplate_155.sv \
                              SRAMTemplate_159.sv SRAMTemplate_162.sv SRAMTemplate_163.sv SRAMTemplate_164.sv \
                              SRAMTemplate_165.sv SRAMTemplate_166.sv SRAMTemplate_178.sv SRAMTemplate_181.sv \
                              SRAMTemplate_185.sv SRAMTemplate_186.sv SRAMTemplate_187.sv SinkA.sv SinkC.sv \
                              Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv SourceB.sv SplittedSRAM_3.sv \
                              SplittedSRAM_4.sv SplittedSRAM_5.sv SplittedSRAM_6.sv TXDAT.sv TXREQ.sv TXRSP.sv \
                              TopDownMonitor.sv VBestOffsetPrefetch.sv array_13.sv array_14.sv array_15.sv \
                              array_16.sv array_17.sv array_18.sv ram_16x11.sv ram_16x137.sv ram_16x25.sv \
                              ram_16x62.sv ram_16x67.sv ram_2x15.sv ram_2x98.sv ram_4x11.sv ram_4x115.sv \
                              ram_data_16x256.sv sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
                              sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
                              sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
                              sram_array_1p512x16m16s1h0l1b_l2_repl.sv sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
                              sram_array_1p512x8m1s1h0l1b_l2_orgb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,TL2CHICoupledL2.sv $(FM_REF_DEPS_TL2CHICoupledL2) $(BB_RAM) $(VENDOR_EXT))
FM_VARIANTS = TL2CHICoupledL2
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用；golden 里本就有同方程的寄存器对
# （§1 两条 RegNextN 链、各 child 内部），两侧逐个保留、逐个配对。
FM_MERGE_DUP = false
FM_MODE = assembly
FM_ALLOWLIST ?= 0
# vmucp（加强不是放宽）：37783 个对称 matched-unread 点，依据与六条证据见 verif/fm_target_config/TL2CHICoupledL2.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

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
	python3 ../../../scripts/gen_tl2chi.py --check
