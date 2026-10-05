MODULE = Frontend

# Frontend —— 前端顶层装配（golden 10,940 行 / 441 端口 / 23 个直接子模块）。
# 子模块处置：整棵前端子树**两侧白盒**，一直重写到厂商宏为止：
#   ref  = golden Frontend + golden 子树（185 个模块文件）；
#   impl = rtl/frontend/Frontend.sv（可读核 + 生成 wrapper）+ 子树里每个模块的已签核重写件
#          （各自 evidence/ 下 receipt 的 impl 闭包，与当前字节一致；清单见 docs/lanes/frontend-asm_prereg.md）；
#   两侧同读的 golden 叶子：存储宏链 sram_array_* / array_* 与 MbistClockGateCell（RTL_GOLDEN_DEPS），
#   ClockGate 用本地件 rtl/common/ClockGate.sv（codex 0208）；
#   黑盒：只有宏内叶子 array_*_ext（vendor_macro，UT 里由 GOLDEN_SRCS 的 .v 行为模型两侧共用）。
RTL_DIR = ../../../rtl
RTL_SRCS = $(XSSV_HOME)/rtl/frontend/InstrMMIOEntry.sv \
    $(XSSV_HOME)/rtl/mmu/PTWFilter.sv \
    $(XSSV_HOME)/rtl/frontend/Predictor.sv \
    $(XSSV_HOME)/rtl/frontend/Composer.sv \
    $(XSSV_HOME)/rtl/frontend/frontend_common_pkg.sv \
    $(XSSV_HOME)/rtl/frontend/FauFTB.sv \
    $(XSSV_HOME)/rtl/frontend/FTB.sv \
    $(XSSV_HOME)/rtl/frontend/ITTage.sv \
    $(XSSV_HOME)/rtl/frontend/RASStack.sv \
    $(XSSV_HOME)/rtl/frontend/RAS.sv \
    $(XSSV_HOME)/rtl/frontend/sctable_pkg.sv \
    $(XSSV_HOME)/rtl/frontend/TageBTable.sv \
    $(XSSV_HOME)/rtl/frontend/Tage_SC.sv \
    $(XSSV_HOME)/rtl/memblock/memblock_common_pkg.sv \
    $(XSSV_HOME)/rtl/memblock/xs_TLBFA_core.sv \
    $(XSSV_HOME)/rtl/memblock/TLB.sv \
    $(XSSV_HOME)/rtl/frontend/IBuffer.sv \
    $(XSSV_HOME)/rtl/memblock/PMP.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMainPipe.sv \
    $(XSSV_HOME)/rtl/frontend/IPrefetchPipe.sv \
    $(XSSV_HOME)/rtl/frontend/WayLookup.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMissUnit.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMetaArray.sv \
    $(XSSV_HOME)/rtl/frontend/ICache.sv \
    $(XSSV_HOME)/rtl/frontend/NewIFU.sv \
    $(XSSV_HOME)/rtl/frontend/RVCExpander.sv \
    $(XSSV_HOME)/rtl/frontend/PredChecker.sv \
    $(XSSV_HOME)/rtl/frontend/FrontendTrigger.sv \
    $(XSSV_HOME)/rtl/frontend/FtqPcMemWrapper.sv \
    $(XSSV_HOME)/rtl/backend/HPerfCounter.sv \
    $(XSSV_HOME)/rtl/backend/PFEvent.sv \
    $(XSSV_HOME)/rtl/backend/PMPChecker_2.sv \
    $(XSSV_HOME)/rtl/backend/perfEventsModule.sv \
    $(XSSV_HOME)/rtl/backend/xs_HPerfCounter_core.sv \
    $(XSSV_HOME)/rtl/backend/xs_PMPChecker_core.sv \
    $(XSSV_HOME)/rtl/common/DelayN.sv \
    $(XSSV_HOME)/rtl/common/DelayNWithValid.sv \
    $(XSSV_HOME)/rtl/common/DelayNWithValid_1.sv \
    $(XSSV_HOME)/rtl/common/DelayN_1.sv \
    $(XSSV_HOME)/rtl/common/DelayN_13.sv \
    $(XSSV_HOME)/rtl/common/DelayN_7.sv \
    $(XSSV_HOME)/rtl/common/DelayN_8.sv \
    $(XSSV_HOME)/rtl/common/DelayN_9.sv \
    $(XSSV_HOME)/rtl/common/FoldedSRAMTemplate.sv \
    $(XSSV_HOME)/rtl/common/FoldedSRAMTemplate_1.sv \
    $(XSSV_HOME)/rtl/common/FoldedSRAMTemplate_20.sv \
    $(XSSV_HOME)/rtl/common/FoldedSRAMTemplate_22.sv \
    $(XSSV_HOME)/rtl/common/FoldedSRAMTemplate_24.sv \
    $(XSSV_HOME)/rtl/common/HPerfMonitor.sv \
    $(XSSV_HOME)/rtl/common/IndexableCAMTemplate.sv \
    $(XSSV_HOME)/rtl/common/MaxPeriodFibonacciLFSR.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_16.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_2.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_32.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_36.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_4.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_44.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_45.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_64.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_68.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_76.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_78.sv \
    $(XSSV_HOME)/rtl/common/SRAMTemplate_8.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_1.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_2.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_23.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_25.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_27.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_3.sv \
    $(XSSV_HOME)/rtl/common/SplittedSRAMTemplate_4.sv \
    $(XSSV_HOME)/rtl/common/SyncDataModuleTemplate__64entry.sv \
    $(XSSV_HOME)/rtl/common/SyncDataModuleTemplate__64entry_1.sv \
    $(XSSV_HOME)/rtl/common/SyncDataModuleTemplate__64entry_2.sv \
    $(XSSV_HOME)/rtl/common/SyncDataModuleTemplate__64entry_3.sv \
    $(XSSV_HOME)/rtl/common/xs_BpuStagePc.sv \
    $(XSSV_HOME)/rtl/common/xs_DataModule.sv \
    $(XSSV_HOME)/rtl/common/xs_DelayNWithValid_core.sv \
    $(XSSV_HOME)/rtl/common/xs_DelayN_core.sv \
    $(XSSV_HOME)/rtl/common/xs_PlruReplacer.sv \
    $(XSSV_HOME)/rtl/common/xs_SRAMTemplate_core.sv \
    $(XSSV_HOME)/rtl/common/xs_SyncDataModule.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeFrontend.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeFtb.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeIcacheDataWay0.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeIcacheDataWay1.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeIcacheDataWay2.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeIcacheDataWay3.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeIcacheTag.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeSc.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeSc_1.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeSc_2.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeSc_3.sv \
    $(XSSV_HOME)/rtl/dft/MbistPipeTage.sv \
    $(XSSV_HOME)/rtl/dft/xs_mbist_pipe_core.sv \
    $(XSSV_HOME)/rtl/frontend/Arbiter1_InsUncacheResp.sv \
    $(XSSV_HOME)/rtl/frontend/Arbiter2_ICacheMissReq.sv \
    $(XSSV_HOME)/rtl/frontend/Arbiter5_MSHRAcquire.sv \
    $(XSSV_HOME)/rtl/frontend/DeMultiplexer.sv \
    $(XSSV_HOME)/rtl/frontend/DeMultiplexer_1.sv \
    $(XSSV_HOME)/rtl/frontend/F3Predecoder.sv \
    $(XSSV_HOME)/rtl/frontend/FIFOReg.sv \
    $(XSSV_HOME)/rtl/frontend/FTBBank.sv \
    $(XSSV_HOME)/rtl/frontend/FTBEntryGen.sv \
    $(XSSV_HOME)/rtl/frontend/FauFTBWay.sv \
    $(XSSV_HOME)/rtl/frontend/Ftq.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheCtrlUnit.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheDataArray.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_1.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_10.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_11.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_12.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_13.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_2.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_3.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_4.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_5.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_6.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_7.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_8.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheMSHR_9.sv \
    $(XSSV_HOME)/rtl/frontend/ICacheReplacer.sv \
    $(XSSV_HOME)/rtl/frontend/ITTageTable.sv \
    $(XSSV_HOME)/rtl/frontend/ITTageTable_1.sv \
    $(XSSV_HOME)/rtl/frontend/ITTageTable_2.sv \
    $(XSSV_HOME)/rtl/frontend/ITTageTable_3.sv \
    $(XSSV_HOME)/rtl/frontend/ITTageTable_4.sv \
    $(XSSV_HOME)/rtl/frontend/InstrUncache.sv \
    $(XSSV_HOME)/rtl/frontend/MbistIntfFrontend.sv \
    $(XSSV_HOME)/rtl/frontend/MuxBundle.sv \
    $(XSSV_HOME)/rtl/frontend/PreDecode.sv \
    $(XSSV_HOME)/rtl/frontend/RegionWays.sv \
    $(XSSV_HOME)/rtl/frontend/SCTable.sv \
    $(XSSV_HOME)/rtl/frontend/SCTable_1.sv \
    $(XSSV_HOME)/rtl/frontend/SCTable_2.sv \
    $(XSSV_HOME)/rtl/frontend/SCTable_3.sv \
    $(XSSV_HOME)/rtl/frontend/SRAMTemplateWithFixedWidth.sv \
    $(XSSV_HOME)/rtl/frontend/SRAMTemplateWithFixedWidth_12.sv \
    $(XSSV_HOME)/rtl/frontend/SRAMTemplateWithFixedWidth_28.sv \
    $(XSSV_HOME)/rtl/frontend/SRAMTemplateWithFixedWidth_4.sv \
    $(XSSV_HOME)/rtl/frontend/TageTable.sv \
    $(XSSV_HOME)/rtl/frontend/TageTable_1.sv \
    $(XSSV_HOME)/rtl/frontend/TageTable_2.sv \
    $(XSSV_HOME)/rtl/frontend/TageTable_3.sv \
    $(XSSV_HOME)/rtl/frontend/WrBypass.sv \
    $(XSSV_HOME)/rtl/frontend/WrBypass_32.sv \
    $(XSSV_HOME)/rtl/frontend/WrBypass_33.sv \
    $(XSSV_HOME)/rtl/frontend/WrBypass_41.sv \
    $(XSSV_HOME)/rtl/frontend/WrBypass_43.sv \
    $(XSSV_HOME)/rtl/frontend/xs_DeMultiplexer_core.sv \
    $(XSSV_HOME)/rtl/frontend/xs_FixedPriorityArbiter_core.sv \
    $(XSSV_HOME)/rtl/frontend/xs_ICacheMSHR_core.sv \
    $(XSSV_HOME)/rtl/memblock/TLBFA.sv \
    $(XSSV_HOME)/rtl/memblock/TlbStorageWrapper.sv \
    $(XSSV_HOME)/rtl/memblock/xs_TlbStorageWrapper_core.sv \
    $(XSSV_HOME)/rtl/mmu/PTWRepeaterNB.sv \
    $(XSSV_HOME)/rtl/mmu/xs_PTWRepeaterNB_core.sv \
    $(XSSV_HOME)/rtl/frontend/Frontend.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/MbistClockGateCell.sv \
    $(GOLDEN_RTL)/array.sv \
    $(GOLDEN_RTL)/array_0.sv \
    $(GOLDEN_RTL)/array_1.sv \
    $(GOLDEN_RTL)/array_2.sv \
    $(GOLDEN_RTL)/array_3.sv \
    $(GOLDEN_RTL)/array_4.sv \
    $(GOLDEN_RTL)/array_5.sv \
    $(GOLDEN_RTL)/array_6.sv \
    $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
    $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
    $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
    $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
    $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
    $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
    $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
    $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
    $(XSSV_HOME)/rtl/common/ClockGate.sv

# golden 子树（字面文件名：fm_predict 静态解析本文件，不展开函数）
FM_REF_DEPS_Frontend = InstrUncache.sv \
    InstrMMIOEntry.sv \
    Arbiter1_InsUncacheResp.sv \
    PTWFilter.sv \
    DelayN_1.sv \
    Predictor.sv \
    Composer.sv \
    FauFTB.sv \
    FauFTBWay.sv \
    DelayN.sv \
    FTB.sv \
    DelayNWithValid_1.sv \
    DelayNWithValid.sv \
    FTBBank.sv \
    SplittedSRAMTemplate_2.sv \
    SRAMTemplate_36.sv \
    MbistClockGateCell.sv \
    ClockGate.sv \
    sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
    array_1.sv \
    MbistPipeFtb.sv \
    ITTage.sv \
    RegionWays.sv \
    ITTageTable_1.sv \
    WrBypass_41.sv \
    IndexableCAMTemplate_41.sv \
    data_mem_0_4x2.sv \
    FoldedSRAMTemplate_22.sv \
    SplittedSRAMTemplate_25.sv \
    SRAMTemplate_76.sv \
    sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
    array_6.sv \
    MbistPipeIttage_1.sv \
    ITTageTable_4.sv \
    MbistPipeIttage_4.sv \
    WrBypass_43.sv \
    IndexableCAMTemplate_43.sv \
    FoldedSRAMTemplate_24.sv \
    SplittedSRAMTemplate_27.sv \
    SRAMTemplate_78.sv \
    MaxPeriodFibonacciLFSR.sv \
    ITTageTable_3.sv \
    MbistPipeIttage_3.sv \
    ITTageTable.sv \
    MbistPipeIttage.sv \
    ITTageTable_2.sv \
    MbistPipeIttage_2.sv \
    RAS.sv \
    RASStack.sv \
    Tage_SC.sv \
    TageBTable.sv \
    WrBypass_32.sv \
    data_mem_8x4.sv \
    IndexableCAMTemplate_32.sv \
    FoldedSRAMTemplate_20.sv \
    SplittedSRAMTemplate_23.sv \
    SRAMTemplate_64.sv \
    sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
    array_4.sv \
    SCTable.sv \
    SRAMTemplate_68.sv \
    sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
    array_5.sv \
    WrBypass_33.sv \
    data_mem_16x12.sv \
    IndexableCAMTemplate_33.sv \
    MbistPipeSc.sv \
    SCTable_1.sv \
    MbistPipeSc_1.sv \
    MbistPipeTage.sv \
    TageTable_2.sv \
    WrBypass.sv \
    data_mem_0_8x3.sv \
    IndexableCAMTemplate.sv \
    FoldedSRAMTemplate_1.sv \
    SplittedSRAMTemplate_4.sv \
    SRAMTemplate_45.sv \
    sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
    array_3.sv \
    FoldedSRAMTemplate.sv \
    SplittedSRAMTemplate_3.sv \
    SRAMTemplate_44.sv \
    sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
    array_2.sv \
    TageTable.sv \
    TageTable_1.sv \
    SCTable_2.sv \
    MbistPipeSc_2.sv \
    SCTable_3.sv \
    MbistPipeSc_3.sv \
    TageTable_3.sv \
    PriorityMuxModule_4.sv \
    PriorityMuxModule_16.sv \
    PriorityMuxModule_8.sv \
    PriorityMuxModule.sv \
    PriorityMuxModule_12.sv \
    PriorityMuxModule_20.sv \
    MbistIntfFrontend.sv \
    TLB.sv \
    TlbStorageWrapper.sv \
    TLBFA.sv \
    DelayN_9.sv \
    DelayN_7.sv \
    IBuffer.sv \
    PMP.sv \
    ICache.sv \
    ICacheMissUnit.sv \
    ICacheMSHR_12.sv \
    ICacheMSHR_9.sv \
    ICacheMSHR_2.sv \
    ICacheMSHR_8.sv \
    ICacheMSHR_7.sv \
    ICacheMSHR.sv \
    ICacheMSHR_13.sv \
    DeMultiplexer_1.sv \
    ICacheMSHR_1.sv \
    ICacheMSHR_4.sv \
    ICacheMSHR_10.sv \
    DeMultiplexer.sv \
    FIFOReg.sv \
    MuxBundle.sv \
    ICacheMSHR_6.sv \
    Arbiter5_MSHRAcquire.sv \
    ICacheMSHR_3.sv \
    ICacheMSHR_5.sv \
    ICacheMSHR_11.sv \
    IPrefetchPipe.sv \
    Arbiter2_ICacheMissReq.sv \
    ICacheReplacer.sv \
    ICacheMetaArray.sv \
    SplittedSRAMTemplate.sv \
    SRAMTemplate.sv \
    sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
    array.sv \
    MbistPipeIcacheTag.sv \
    SplittedSRAMTemplate_1.sv \
    SRAMTemplate_2.sv \
    ICacheDataArray.sv \
    SRAMTemplateWithFixedWidth_28.sv \
    SRAMTemplate_32.sv \
    sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
    array_0.sv \
    SRAMTemplateWithFixedWidth.sv \
    SRAMTemplate_4.sv \
    MbistPipeIcacheDataWay2.sv \
    SRAMTemplateWithFixedWidth_12.sv \
    SRAMTemplate_16.sv \
    MbistPipeIcacheDataWay1.sv \
    MbistPipeIcacheDataWay3.sv \
    SRAMTemplateWithFixedWidth_4.sv \
    SRAMTemplate_8.sv \
    MbistPipeIcacheDataWay0.sv \
    WayLookup.sv \
    ICacheMainPipe.sv \
    ICacheCtrlUnit.sv \
    Queue1_RegMapperInput_5.sv \
    PTWRepeaterNB.sv \
    PMPChecker_2.sv \
    DelayN_13.sv \
    HPerfMonitor.sv \
    HPerfCounter.sv \
    PFEvent.sv \
    perfEventsModule.sv \
    NewIFU.sv \
    PreDecode.sv \
    F3Predecoder.sv \
    PredChecker.sv \
    RVCExpander.sv \
    FrontendTrigger.sv \
    DelayN_8.sv \
    Ftq.sv \
    SyncDataModuleTemplate__64entry_1.sv \
    DataModule__16entry_4.sv \
    SyncDataModuleTemplate__64entry_2.sv \
    DataModule__16entry_8.sv \
    SyncDataModuleTemplate__64entry_3.sv \
    DataModule__16entry_12.sv \
    SyncDataModuleTemplate__64entry.sv \
    DataModule__16entry.sv \
    FtqPcMemWrapper.sv \
    SyncDataModuleTemplate_FtqPC_64entry.sv \
    DataModule_FtqPC_16entry.sv \
    FTBEntryGen.sv \
    MbistPipeFrontend.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Frontend.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_Frontend)) \
    $(GOLDEN_RTL)/array_0_ext.v \
    $(GOLDEN_RTL)/array_1_ext.v \
    $(GOLDEN_RTL)/array_2_ext.v \
    $(GOLDEN_RTL)/array_3_ext.v \
    $(GOLDEN_RTL)/array_4_ext.v \
    $(GOLDEN_RTL)/array_5_ext.v \
    $(GOLDEN_RTL)/array_6_ext.v \
    $(GOLDEN_RTL)/array_ext.v

FM_VARIANTS = Frontend
# 唯一黑盒 = 存储宏叶子 array_*_ext（84 对，vendor_macro），逐对象声明在 verif/allow/Frontend.json。
FM_MODE = assembly
# 不合并重复寄存器：Predictor 打开 merge 到达 Matching 慢 7 倍（docs/predictor_fm_scaling_wall.md）；golden 的恒等副本
# 改由钉点第四节（FM 结构识别的副本组，一对多）配对。比较点 = 寄存器位 + 输出位 + 黑盒输入位，fm_predict 模型严格适用。
FM_MERGE_DUP = false
# 两侧对称死位（子模块各自签核时已由 vmucp 真比较的那批）在本层继续真比；依据与六条见 verif/fm_target_config/Frontend.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# 初值档 INITREG（编译期打开机制，运行期选档；与 verif/ut/DCache 同一做法）：
#   0        +vcs+initreg+0：全设计 0，复位后全比；
#   glue     子模块 0、两侧 Frontend 本层（golden 顶层 / 重写侧 u_core）随机（种子 = SEED）；
#   glue017  同上，种子 = <SEED>017（不经 ntb 种子，seed 1 也是真随机）。
#   为什么不是全设计 +vcs+initreg+random：子模块两侧各摇各的初值（SRAM 阵列内容也在内），
#   比出来的只是初值噪声，与本层重写无关（CONVENTIONS「双例化 UT」）。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
INITREG_CFG = $(UT_GEN_DIR)/initreg_$(INITREG)_$(SEED).cfg
ifeq ($(INITREG),0)
SIM_ARGS += +vcs+initreg+0
else ifeq ($(INITREG),glue)
SIM_ARGS += +vcs+initreg+config+$(INITREG_CFG)
INITREG_SEED = $(SEED)
else ifeq ($(INITREG),glue017)
SIM_ARGS += +vcs+initreg+config+$(INITREG_CFG)
INITREG_SEED = $(SEED)017
else
$(error INITREG 只认 0 / glue / glue017)
endif

run: initreg_cfg
.PHONY: initreg_cfg gencheck gentb
initreg_cfg:
	@mkdir -p $(UT_GEN_DIR)
	@$(if $(INITREG_SEED),printf 'defaultvalue 0\ninstance tb.u_g_Frontend random $(INITREG_SEED)\ninstance tb.u_i_Frontend.u_core random $(INITREG_SEED)\n' > $(INITREG_CFG),:)

gencheck:
	python3 ../../../scripts/gen_frontend.py --check
	python3 gen.py --check
gentb:
	python3 gen.py

# 实例对应表（FM 钉点重定位用）：从 simv 的实际层次机械生成，见 scripts/gen_frontend.py 的「子树钉点重定位」。
.PHONY: hiermap
hiermap: simv
	./simv -ucli -i hiermap.tcl -l ut_gen/hiermap.log +ncycles=1 > /dev/null
	python3 ../../../scripts/gen_frontend.py --refresh-inst-map ut_gen/hier_dump.txt
