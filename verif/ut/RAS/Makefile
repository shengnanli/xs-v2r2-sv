MODULE = RAS

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 (含 xs_RASStack) + 顶层 xs_RAS_core
RTL_SRCS = $(RTL_DIR)/frontend/RAS.sv $(RTL_DIR)/frontend/RAS_core_top.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/RAS_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RAS.sv $(GOLDEN_RTL)/RASStack.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RAS
FM_REF_DEPS_RAS = RASStack.sv

include ../../../scripts/ut_common.mk
