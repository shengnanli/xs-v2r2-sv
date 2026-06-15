MODULE = FoldedSRAMTemplate_21

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
            $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/array_6_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Folded（内层 SplittedSRAMTemplate 当黑盒，不读其定义）
WRAPPER_SRCS = $(RTL_DIR)/common/FoldedSRAMTemplate_variants.sv
# UT：golden Folded + golden 内层 Splitted + golden SRAMTemplate + 宏链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/FoldedSRAMTemplate_21.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_24.sv $(GOLDEN_RTL)/SRAMTemplate_70.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Folded（内层 Splitted 黑盒）；impl = 我的 Folded（内层 Splitted 黑盒）
FM_VARIANTS = FoldedSRAMTemplate_21
FM_REF_DEPS_FoldedSRAMTemplate_21 =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
