MODULE = IBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/IBuffer.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/IBuffer_wrapper.sv
# golden IBuffer 自包含, 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/IBuffer.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = IBuffer
FM_REF_DEPS_IBuffer =

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言; UT 随机激励下定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

include ../../../scripts/ut_common.mk
