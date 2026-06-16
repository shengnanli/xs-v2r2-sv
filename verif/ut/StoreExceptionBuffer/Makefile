MODULE = StoreExceptionBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 共享类型/年龄比较包（纯叶子，无子模块）
RTL_SRCS = $(RTL_DIR)/memblock/exceptionbuffer_pkg.sv \
           $(RTL_DIR)/memblock/StoreExceptionBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化：golden 顶层 StoreExceptionBuffer（纯叶子）vs 手写 _xs 别名（→ 可读核）。
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreExceptionBuffer.sv

# FM：golden 顶层 vs 手写同名 wrapper（→ 可读核）。纯叶子，应可干净判等。
WRAPPER_SRCS = $(RTL_DIR)/memblock/StoreExceptionBuffer_wrapper.sv
FM_VARIANTS = StoreExceptionBuffer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
