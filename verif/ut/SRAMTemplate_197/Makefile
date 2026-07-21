MODULE = SRAMTemplate_197

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# impl(可读): 独立单口写优先 SRAM 核 + 薄 wrapper
RTL_SRCS = $(RTL_DIR)/common/xs_Simple1PSRAM_core.sv \
           $(RTL_DIR)/uncore/SRAMTemplate_197.sv
WRAPPER_SRCS =

# FM ref = golden SRAMTemplate_197 + array_19 + array_19_ext(行为RAM全展开, strict无黑盒)
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate_197.sv \
              $(GOLDEN_RTL)/array_19.sv \
              $(GOLDEN_RTL)/array_19_ext.v

TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SRAMTemplate_197
FM_REF_DEPS_SRAMTemplate_197 = array_19.sv array_19_ext.v

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
