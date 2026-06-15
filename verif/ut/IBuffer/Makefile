MODULE = IBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/IBuffer.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/IBuffer_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/IBuffer.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = IBuffer

# golden 含 ifndef SYNTHESIS 的随机初始化/断言，UT 关掉避免 X 干扰
VCS += +define+SYNTHESIS

include ../../../scripts/ut_common.mk
