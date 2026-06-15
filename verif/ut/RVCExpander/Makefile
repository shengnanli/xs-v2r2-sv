MODULE = RVCExpander

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/rvc_expander_pkg.sv $(RTL_DIR)/frontend/RVCExpander.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/RVCExpander_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RVCExpander.sv
TB_SRCS = tb.sv

FM_VARIANTS = RVCExpander

include ../../../scripts/ut_common.mk
