MODULE = SplittedSRAMTemplate_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAMTemplate_2(icsh_tag) 宏链
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
            $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv $(GOLDEN_RTL)/SRAMTemplate_2.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SplittedSRAMTemplate_1
FM_REF_DEPS_SplittedSRAMTemplate_1 =

include ../../../scripts/ut_common.mk
