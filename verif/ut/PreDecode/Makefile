MODULE = PreDecode

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/PreDecode.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/PreDecode_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PreDecode.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = PreDecode

include ../../../scripts/ut_common.mk
