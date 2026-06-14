MODULE = F3Predecoder

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/predecode_pkg.sv $(RTL_DIR)/frontend/F3Predecoder.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/F3Predecoder_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/F3Predecoder.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = F3Predecoder

include ../../../scripts/ut_common.mk
