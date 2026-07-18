MODULE = IBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/IBuffer.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/IBuffer_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/IBuffer.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = IBuffer

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 的随机初始化/断言(新基线还有 xs_assert_v2 DPI 调用)，
# UT 关掉避免 X 干扰/未声明标识符。注意必须放在 include 之后：ut_common.mk 用
# `VCS := ...` 无条件赋值，放前面会被覆盖。
VCS += +define+SYNTHESIS
