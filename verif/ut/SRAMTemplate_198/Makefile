MODULE = SRAMTemplate_198
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/common/xs_Simple1PSRAM_core.sv \
           $(RTL_DIR)/uncore/SRAMTemplate_198.sv
WRAPPER_SRCS =
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_198.sv $(GOLDEN_RTL)/array_20.sv $(GOLDEN_RTL)/array_20_ext.v
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = SRAMTemplate_198
FM_REF_DEPS_SRAMTemplate_198 = array_20.sv array_20_ext.v
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
