MODULE = StoreMisalignBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/storemisalignbuffer_pkg.sv \
           $(RTL_DIR)/memblock/StoreMisalignBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StoreMisalignBuffer.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/StoreMisalignBuffer_wrapper.sv
FM_VARIANTS = StoreMisalignBuffer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
