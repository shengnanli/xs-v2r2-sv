MODULE = BPU_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）BPU 簇：golden Predictor (u_g) vs 全重写 Predictor_it (u_i)
#
#   Predictor_it  : 顶层端口 = golden Predictor；内部 Composer 实例换成 Composer_it，
#                   保留 xs_Predictor_core（在环 FSM 观察核）。
#   Composer_it   : 5 个预测器实例全部换成重写叶子适配器 + xs_Composer_core。
#   RAS_it        : golden RAS 簿记壳 + 重写 RASStack_xs 内核。
#
#   叶子适配器（*_xs，纯端口搬运 + 重写 xs_*_core，无 golden 算法叶子）直接复用
#   各模块 UT 的 verif/ut/<M>/variants_xs.sv（每个文件仅含 1 个适配器模块）。
#
#   叶子边界 = SRAM 模板 / SRAM 宏（存储原语，golden 与 rewrite 共用，非算法）。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：xs 核 + 叶子适配器 + IT 装配
# ---------------------------------------------------------------------------
# -- 重写 xs 核（算法逻辑全部在这里） --
XS_CORES = \
    $(RTL_DIR)/frontend/ftb_pkg.sv \
    $(RTL_DIR)/frontend/FTB.sv \
    $(RTL_DIR)/frontend/FauFTBWay.sv \
    $(RTL_DIR)/frontend/FauFTB.sv \
    $(RTL_DIR)/frontend/Tage_SC.sv \
    $(RTL_DIR)/frontend/ITTage.sv \
    $(RTL_DIR)/frontend/RAS.sv \
    $(RTL_DIR)/frontend/Composer.sv \
    $(RTL_DIR)/frontend/Predictor.sv

# -- 重写叶子适配器（golden 扁平端口 -> xs 核；复用各模块 UT 的 variants_xs.sv） --
XS_ADAPTERS = \
    $(UT_DIR)/FTB/variants_xs.sv \
    $(UT_DIR)/FauFTB/variants_xs.sv \
    $(UT_DIR)/Tage_SC/variants_xs.sv \
    $(UT_DIR)/ITTage/variants_xs.sv \
    $(UT_DIR)/RAS/variants_xs.sv

# -- IT 装配（本目录） --
IT_ASSEMBLY = \
    RAS_it.sv \
    Composer_it.sv \
    Predictor_it.sv

# ---------------------------------------------------------------------------
# golden 叶子：被 rewrite 适配器 / RAS_it 内部直接例化的存储原语 + DelayN 等纯结构件，
#   以及 u_g 顶层用到的 golden Predictor + Composer + 5 预测器全链。
#   （与 Predictor UT 的 GOLDEN_SRCS 同一批；两侧均例化同一份 SRAM 宏。）
# ---------------------------------------------------------------------------

# ---- SRAM 宏模型 ----
MACRO_SIM = \
    $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
    $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/array_1_ext.v \
    $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
    $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/array_2_ext.v \
    $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
    $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v \
    $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
    $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/array_4_ext.v \
    $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv \
    $(GOLDEN_RTL)/array_5.sv $(GOLDEN_RTL)/array_5_ext.v \
    $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
    $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/array_6_ext.v \
    $(GOLDEN_RTL)/array_ext.v \
    $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# ---- golden 存储原语 / 结构件，供两侧共用（rewrite 适配器内部也例化这些） ----
FTB_GOLD = $(GOLDEN_RTL)/FTBBank.sv \
           $(GOLDEN_RTL)/MbistPipeFtb.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
           $(GOLDEN_RTL)/SRAMTemplate_36.sv \
           $(GOLDEN_RTL)/DelayNWithValid.sv $(GOLDEN_RTL)/DelayNWithValid_1.sv \
           $(GOLDEN_RTL)/DelayN_1.sv

TAGE_GOLD = $(GOLDEN_RTL)/TageTable.sv $(GOLDEN_RTL)/TageTable_1.sv \
            $(GOLDEN_RTL)/TageTable_2.sv $(GOLDEN_RTL)/TageTable_3.sv \
            $(GOLDEN_RTL)/TageBTable.sv \
            $(GOLDEN_RTL)/SCTable.sv $(GOLDEN_RTL)/SCTable_1.sv \
            $(GOLDEN_RTL)/SCTable_2.sv $(GOLDEN_RTL)/SCTable_3.sv \
            $(GOLDEN_RTL)/MbistPipeTage.sv \
            $(GOLDEN_RTL)/MbistPipeSc.sv $(GOLDEN_RTL)/MbistPipeSc_1.sv \
            $(GOLDEN_RTL)/MbistPipeSc_2.sv $(GOLDEN_RTL)/MbistPipeSc_3.sv \
            $(GOLDEN_RTL)/FoldedSRAMTemplate.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
            $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
            $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
            $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
            $(GOLDEN_RTL)/SRAMTemplate_44.sv $(GOLDEN_RTL)/SRAMTemplate_45.sv \
            $(GOLDEN_RTL)/SRAMTemplate_64.sv $(GOLDEN_RTL)/SRAMTemplate_66.sv \
            $(GOLDEN_RTL)/WrBypass.sv $(GOLDEN_RTL)/WrBypass_32.sv $(GOLDEN_RTL)/WrBypass_33.sv \
            $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
            $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
            $(GOLDEN_RTL)/data_mem_0_8x3.sv $(GOLDEN_RTL)/data_mem_8x4.sv \
            $(GOLDEN_RTL)/data_mem_16x12.sv

ITTAGE_GOLD = $(GOLDEN_RTL)/ITTageTable.sv $(GOLDEN_RTL)/ITTageTable_1.sv \
              $(GOLDEN_RTL)/ITTageTable_2.sv $(GOLDEN_RTL)/ITTageTable_3.sv \
              $(GOLDEN_RTL)/ITTageTable_4.sv \
              $(GOLDEN_RTL)/RegionWays.sv \
              $(GOLDEN_RTL)/MbistPipeIttage.sv $(GOLDEN_RTL)/MbistPipeIttage_1.sv \
              $(GOLDEN_RTL)/MbistPipeIttage_2.sv $(GOLDEN_RTL)/MbistPipeIttage_3.sv \
              $(GOLDEN_RTL)/MbistPipeIttage_4.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_21.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_24.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_26.sv \
              $(GOLDEN_RTL)/SRAMTemplate_70.sv $(GOLDEN_RTL)/SRAMTemplate_72.sv \
              $(GOLDEN_RTL)/WrBypass_41.sv $(GOLDEN_RTL)/WrBypass_43.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
              $(GOLDEN_RTL)/data_mem_0_4x2.sv

MISC_GOLD = $(GOLDEN_RTL)/FauFTBWay.sv \
            $(GOLDEN_RTL)/RASStack.sv \
            $(GOLDEN_RTL)/DelayN.sv \
            $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

# u_g 顶层独有：golden Predictor + Composer + 5 个 golden 预测器顶层 + PriorityMuxModule
GOLD_TOP = $(GOLDEN_RTL)/Predictor.sv \
           $(GOLDEN_RTL)/Composer.sv \
           $(GOLDEN_RTL)/FTB.sv $(GOLDEN_RTL)/FauFTB.sv \
           $(GOLDEN_RTL)/Tage_SC.sv $(GOLDEN_RTL)/ITTage.sv $(GOLDEN_RTL)/RAS.sv \
           $(GOLDEN_RTL)/PriorityMuxModule.sv $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
           $(GOLDEN_RTL)/PriorityMuxModule_8.sv $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
           $(GOLDEN_RTL)/PriorityMuxModule_16.sv $(GOLDEN_RTL)/PriorityMuxModule_20.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) \
              $(FTB_GOLD) $(TAGE_GOLD) $(ITTAGE_GOLD) $(MISC_GOLD) \
              $(MACRO_SIM)

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 随机初值/运行时断言；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
