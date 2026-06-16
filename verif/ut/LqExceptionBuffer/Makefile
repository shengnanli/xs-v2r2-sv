MODULE = LqExceptionBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 共享类型/年龄比较包（纯叶子，无子模块）
RTL_SRCS = $(RTL_DIR)/memblock/exceptionbuffer_pkg.sv \
           $(RTL_DIR)/memblock/LqExceptionBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化：golden 顶层 LqExceptionBuffer（纯叶子）vs 手写 _xs 别名（→ 可读核）。
GOLDEN_SRCS = $(GOLDEN_RTL)/LqExceptionBuffer.sv

# FM：golden 顶层 vs 手写同名 wrapper（→ 可读核）。纯叶子，应可干净判等。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LqExceptionBuffer_wrapper.sv
FM_VARIANTS = LqExceptionBuffer

include ../../../scripts/ut_common.mk

# golden 含 XSPerf 行为代码；UT 关随机初始化。
VCS += +define+SYNTHESIS
