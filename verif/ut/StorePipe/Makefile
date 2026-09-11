MODULE = StorePipe

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/StorePipe.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StorePipe.sv
FM_VARIANTS = StorePipe

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
