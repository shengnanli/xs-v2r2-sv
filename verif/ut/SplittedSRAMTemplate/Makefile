MODULE = SplittedSRAMTemplate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# icsh_tag 内层 SRAMTemplate 宏链（UT 需可仿真 array_ext.v）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
            $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Splitted（内层 SRAMTemplate 当黑盒，不读其定义）
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
# UT：golden Splitted + golden 内层 SRAMTemplate + 宏链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate.sv $(GOLDEN_RTL)/SRAMTemplate.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Splitted（SRAMTemplate 黑盒）；impl = 我的 Splitted（SRAMTemplate 黑盒）
FM_VARIANTS = SplittedSRAMTemplate
FM_REF_DEPS_SplittedSRAMTemplate =

include ../../../scripts/ut_common.mk
