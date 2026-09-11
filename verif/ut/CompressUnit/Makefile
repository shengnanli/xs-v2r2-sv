MODULE = CompressUnit

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CompressUnit.sv
TB_SRCS = cu_bridge.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CompressUnit.sv
FM_VARIANTS = CompressUnit

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
