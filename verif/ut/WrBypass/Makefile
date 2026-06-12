MODULE = WrBypass

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/IndexableCAM.sv \
           $(RTL_DIR)/common/PlruReplacer.sv \
           $(RTL_DIR)/frontend/WrBypass.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/WrBypass_variants.sv
TB_SRCS = tb.sv

GOLDEN_RTL = ../../../golden/chisel-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/WrBypass.sv    $(GOLDEN_RTL)/IndexableCAMTemplate.sv    $(GOLDEN_RTL)/data_mem_0_8x3.sv \
              $(GOLDEN_RTL)/WrBypass_32.sv $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv $(GOLDEN_RTL)/data_mem_8x4.sv \
              $(GOLDEN_RTL)/WrBypass_33.sv $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv $(GOLDEN_RTL)/data_mem_16x12.sv \
              $(GOLDEN_RTL)/WrBypass_41.sv $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv $(GOLDEN_RTL)/data_mem_0_4x2.sv \
              $(GOLDEN_RTL)/WrBypass_43.sv $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv

FM_VARIANTS = WrBypass WrBypass_32 WrBypass_33 WrBypass_41 WrBypass_43
FM_REF_DEPS_WrBypass    = IndexableCAMTemplate.sv    data_mem_0_8x3.sv
FM_REF_DEPS_WrBypass_32 = IndexableCAMTemplate_32.sv data_mem_8x4.sv
FM_REF_DEPS_WrBypass_33 = IndexableCAMTemplate_33.sv data_mem_16x12.sv
FM_REF_DEPS_WrBypass_41 = IndexableCAMTemplate_41.sv data_mem_0_4x2.sv
FM_REF_DEPS_WrBypass_43 = IndexableCAMTemplate_43.sv data_mem_0_4x2.sv

include ../../../scripts/ut_common.mk
