MODULE = Composer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# ---------------------------------------------------------------------------
# 可读核：xs_Composer_core（perf 对齐 / meta 拼接 / s1_ready 相与）
# ---------------------------------------------------------------------------
RTL_SRCS = $(RTL_DIR)/frontend/Composer.sv
# FM impl：核 + golden 同名 wrapper（5 预测器 + 4 DelayN 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/frontend/Composer_wrapper.sv

# ---------------------------------------------------------------------------
# UT 双例化所需 golden RTL：Composer 顶层 + 5 个预测器及其完整子模块链 + DelayN。
#   golden Composer 与 Composer_xs 两侧共用同一批 golden 预测器子模块，
#   故任何输出差异只可能来自 Composer 自身逻辑（perf/meta/ready/接线）。
# ---------------------------------------------------------------------------

# ---- SRAM 宏模型（各预测器内层 sram_array_* → array_* → *_ext）----
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

# ---- FTB 子模块链 ----
FTB_SRCS = $(GOLDEN_RTL)/FTB.sv $(GOLDEN_RTL)/FTBBank.sv \
           $(GOLDEN_RTL)/MbistPipeFtb.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
           $(GOLDEN_RTL)/SRAMTemplate_36.sv \
           $(GOLDEN_RTL)/DelayNWithValid.sv $(GOLDEN_RTL)/DelayNWithValid_1.sv \
           $(GOLDEN_RTL)/DelayN_1.sv

# ---- TAGE-SC 子模块链 ----
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

# ---- ITTAGE 子模块链 ----
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

# ---- uFTB / RAS / DelayN / LFSR（多预测器共享）----
MISC_SRCS = $(GOLDEN_RTL)/FauFTB.sv $(GOLDEN_RTL)/FauFTBWay.sv \
            $(GOLDEN_RTL)/RAS.sv $(GOLDEN_RTL)/RASStack.sv \
            $(GOLDEN_RTL)/DelayN.sv \
            $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Composer.sv \
              $(FTB_SRCS) $(TAGE_SRCS) $(ITTAGE_SRCS) $(MISC_SRCS) \
              $(MACRO_SIM)

TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Composer（5 预测器 + DelayN 不列依赖 → hdlin_unresolved_modules=black_box
#   两侧同名黑盒）；impl = 可读核 + golden 同名 wrapper（同样把预测器当黑盒）。
FM_VARIANTS = Composer
# 5 预测器用**接口桩**(predictor_stubs.sv: 只有端口声明的空模块), 两侧同读——
# unresolved blackbox 引脚方向未知, 会把预测器输出(io_out_last_stage_meta 等)
# 当输入建 2186 个 Und 比对点+同数 failing(全部假阳性)。桩只给 FM 方向信息,
# 逻辑仍为空(等价黑盒), 预测器内部在各自 UT/FM 单独验证。DelayN 小, 直接给真源。
FM_REF_DEPS_Composer = ../../verif/ut/Composer/predictor_stubs.sv DelayN.sv
# impl 侧同读桩与 DelayN(仅 FM 用; UT 编译不含 WRAPPER_SRCS, 不会与真源重定义)
WRAPPER_SRCS += predictor_stubs.sv $(GOLDEN_RTL)/DelayN.sv

include ../../../scripts/ut_common.mk

# golden 各预测器子模块含 `ifndef SYNTHESIS 的随机初始化与运行时断言（RAS BOS 距离、
# FauFTB fallThrough 等），随机激励会误触发 $fatal。定义 SYNTHESIS 关掉断言与随机初值，
# 两侧均从复位态出发；WARMUP（tb 内）大于子模块内层 SRAM 清零拍数。
VCS += +define+SYNTHESIS
