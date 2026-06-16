MODULE = LoadMisalignBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（纯叶子，无子模块）
RTL_SRCS = $(RTL_DIR)/memblock/loadmisalignbuffer_pkg.sv \
           $(RTL_DIR)/memblock/LoadMisalignBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层（纯叶子）。UT 双例化两侧逐拍比对全部输出。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadMisalignBuffer.sv

# FM：golden 顶层 vs 手写同名 wrapper(→ 可读核)。纯叶子，应可干净比对。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadMisalignBuffer_wrapper.sv
FM_VARIANTS = LoadMisalignBuffer

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
