MODULE = SRAMTemplate_201
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/uncore/SRAMTemplate_201.sv
WRAPPER_SRCS = $(GOLDEN_RTL)/array_0_0.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_201.sv $(GOLDEN_RTL)/array_0_0.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = SRAMTemplate_201
FM_REF_DEPS_SRAMTemplate_201 = array_0_0.sv
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
