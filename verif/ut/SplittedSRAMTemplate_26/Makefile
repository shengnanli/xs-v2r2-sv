MODULE = SplittedSRAMTemplate_26

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
            $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/array_6_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate_26.sv $(GOLDEN_RTL)/SRAMTemplate_72.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SplittedSRAMTemplate_26
FM_REF_DEPS_SplittedSRAMTemplate_26 =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
