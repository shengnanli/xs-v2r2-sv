MODULE = FoldedSRAMTemplate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
            $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/array_2_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Folded（内层 SplittedSRAMTemplate 当黑盒，不读其定义）
WRAPPER_SRCS = $(RTL_DIR)/common/FoldedSRAMTemplate_variants.sv
# UT：golden Folded + golden 内层 Splitted + golden SRAMTemplate + 宏链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/FoldedSRAMTemplate.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv $(GOLDEN_RTL)/SRAMTemplate_44.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Folded（内层 Splitted 黑盒）；impl = 我的 Folded（内层 Splitted 黑盒）
FM_VARIANTS = FoldedSRAMTemplate
FM_REF_DEPS_FoldedSRAMTemplate =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
