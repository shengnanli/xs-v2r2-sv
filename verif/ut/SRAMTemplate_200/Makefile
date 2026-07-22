MODULE = SRAMTemplate_200
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/uncore/SRAMTemplate_200.sv
WRAPPER_SRCS = $(GOLDEN_RTL)/array_22.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_200.sv $(GOLDEN_RTL)/array_22.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = SRAMTemplate_200
FM_REF_DEPS_SRAMTemplate_200 = array_22.sv
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
