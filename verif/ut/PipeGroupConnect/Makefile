MODULE = PipeGroupConnect

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/PipeGroupConnect_core.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PipeGroupConnect.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/PipeGroupConnect_wrapper.sv
FM_VARIANTS = PipeGroupConnect

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
