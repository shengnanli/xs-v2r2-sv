MODULE = InstrUncache
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/frontend/InstrMMIOEntry.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/InstrUncache_variants.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/InstrMMIOEntry.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = InstrMMIOEntry Arbiter1_InsUncacheResp InstrUncache
FM_REF_DEPS_InstrUncache = InstrMMIOEntry.sv Arbiter1_InsUncacheResp.sv
include ../../../scripts/ut_common.mk
