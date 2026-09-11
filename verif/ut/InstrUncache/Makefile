MODULE = Arbiter1_InsUncacheResp

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/Arbiter1_InsUncacheResp.sv \
           $(RTL_DIR)/frontend/InstrMMIOEntry.sv \
           $(RTL_DIR)/frontend/InstrUncache.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/InstrMMIOEntry.sv
FM_REF_DEPS_InstrUncache = InstrMMIOEntry.sv Arbiter1_InsUncacheResp.sv
FM_VARIANTS = InstrMMIOEntry Arbiter1_InsUncacheResp InstrUncache

include ../../../scripts/ut_common.mk
