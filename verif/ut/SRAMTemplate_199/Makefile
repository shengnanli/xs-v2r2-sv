MODULE = SRAMTemplate_199
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/uncore/SRAMTemplate_199.sv
WRAPPER_SRCS = $(GOLDEN_RTL)/array_21.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_199.sv $(GOLDEN_RTL)/array_21.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = SRAMTemplate_199
FM_REF_DEPS_SRAMTemplate_199 = array_21.sv
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
