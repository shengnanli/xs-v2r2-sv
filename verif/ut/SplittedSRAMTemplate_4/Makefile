MODULE = SplittedSRAMTemplate_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAMTemplate_45(bp_tage) 宏链
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
            $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv $(GOLDEN_RTL)/SRAMTemplate_45.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SplittedSRAMTemplate_4
FM_REF_DEPS_SplittedSRAMTemplate_4 =

include ../../../scripts/ut_common.mk
