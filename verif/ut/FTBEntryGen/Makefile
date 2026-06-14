MODULE = FTBEntryGen

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/ftb_pkg.sv $(RTL_DIR)/frontend/FTBEntryGen.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/FTBEntryGen_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FTBEntryGen.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FTBEntryGen

include ../../../scripts/ut_common.mk
