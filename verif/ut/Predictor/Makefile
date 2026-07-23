MODULE = Predictor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# ---------------------------------------------------------------------------
# 可读核：xs_Predictor_core（BPU 流水 FSM + topdown 气泡原因）
# ---------------------------------------------------------------------------
RTL_SRCS = $(RTL_DIR)/frontend/Predictor.sv
# FM impl：可读核 + golden 同名 wrapper。
#   Composer 走 assembly 黑盒（305 绿 child，depends_on）；
#   DelayN + 6 种 PriorityMuxModule 是非 vendor 纯逻辑叶子（PMM 全组合、DelayN 确定性
#   移位延迟），两侧 elaborate 白盒受验（reviewer 裁定：纯逻辑子模块不黑盒）。
PRED_LOGIC_LEAVES = \
    $(GOLDEN_RTL)/DelayN.sv \
    $(GOLDEN_RTL)/PriorityMuxModule.sv $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
    $(GOLDEN_RTL)/PriorityMuxModule_8.sv $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
    $(GOLDEN_RTL)/PriorityMuxModule_16.sv $(GOLDEN_RTL)/PriorityMuxModule_20.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/Predictor_wrapper.sv $(PRED_LOGIC_LEAVES)

# ---------------------------------------------------------------------------
# UT 双例化所需 golden RTL：Predictor 顶层依赖 Composer（含 5 预测器完整子模块链）+
#   DelayN + 6 种 PriorityMuxModule。golden Predictor 与 Predictor_xs 共用同一批
#   golden 子模块，故输出差异只可能来自 Predictor 自身（其实就是 wrapper 照搬 body，
#   两侧仅模块名不同 + _xs 多例化可读核影子 + xs_dbg_* 调试口）。
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

FTB_SRCS = $(GOLDEN_RTL)/FTB.sv $(GOLDEN_RTL)/FTBBank.sv \
           $(GOLDEN_RTL)/MbistPipeFtb.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
           $(GOLDEN_RTL)/SRAMTemplate_36.sv \
           $(GOLDEN_RTL)/DelayNWithValid.sv $(GOLDEN_RTL)/DelayNWithValid_1.sv \
           $(GOLDEN_RTL)/DelayN_1.sv

TAGE_SRCS = $(GOLDEN_RTL)/Tage_SC.sv \
            $(GOLDEN_RTL)/TageTable.sv $(GOLDEN_RTL)/TageTable_1.sv \
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

ITTAGE_SRCS = $(GOLDEN_RTL)/ITTage.sv \
              $(GOLDEN_RTL)/ITTageTable.sv $(GOLDEN_RTL)/ITTageTable_1.sv \
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

MISC_SRCS = $(GOLDEN_RTL)/FauFTB.sv $(GOLDEN_RTL)/FauFTBWay.sv \
            $(GOLDEN_RTL)/RAS.sv $(GOLDEN_RTL)/RASStack.sv \
            $(GOLDEN_RTL)/DelayN.sv \
            $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

# ---- Predictor 顶层独有依赖：Composer + 6 种 PriorityMuxModule ----
TOP_SRCS = $(GOLDEN_RTL)/Composer.sv \
           $(GOLDEN_RTL)/PriorityMuxModule.sv $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
           $(GOLDEN_RTL)/PriorityMuxModule_8.sv $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
           $(GOLDEN_RTL)/PriorityMuxModule_16.sv $(GOLDEN_RTL)/PriorityMuxModule_20.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Predictor.sv \
              $(TOP_SRCS) \
              $(FTB_SRCS) $(TAGE_SRCS) $(ITTAGE_SRCS) $(MISC_SRCS) \
              $(MACRO_SIM)

TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Predictor + DelayN/PriorityMuxModule 纯逻辑叶子依赖（两侧 elaborate 白盒）；
#   Composer 不列依赖 → 两侧同名黑盒（assembly，305 绿 child depends_on）。
#   impl = 可读核 xs_Predictor_core（真驱动 FSM + topdown 输出）+ golden 同名 wrapper body。
# assembly：唯一黑盒=Composer(实例 predictors, allow/Predictor.json)。
# 残留 627 对称 matched-unread(predCycle_c/previous_s2/powerOnReset 死寄存器, ref==impl
#   双射, golden 与 wrapper body 同源)= vmucp-ready。要转 SUCCEEDED 由集成方(Main)按
#   standing rule 把 Predictor 加入 4 处 vmucp 白名单 + declarations vmucp=true(本 worker
#   不改共享 verdict/manifest 基础设施)。
FM_VARIANTS = Predictor
FM_REF_DEPS_Predictor = DelayN.sv \
    PriorityMuxModule.sv PriorityMuxModule_4.sv PriorityMuxModule_8.sv \
    PriorityMuxModule_12.sv PriorityMuxModule_16.sv PriorityMuxModule_20.sv
FM_MODE = assembly

include ../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 的随机初始化与运行时断言，随机激励会误触发 $fatal。
# 定义 SYNTHESIS 关掉断言与随机初值；WARMUP（tb 内）大于子模块内层 SRAM 清零拍数。
VCS += +define+SYNTHESIS
