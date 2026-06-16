MODULE = VirtualLoadQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包
RTL_SRCS = $(RTL_DIR)/memblock/virtualloadqueue_pkg.sv \
           $(RTL_DIR)/memblock/VirtualLoadQueue.sv

TB_SRCS = variants_xs.sv tb.sv

# golden VirtualLoadQueue 是纯叶子模块（无子模块），UT 双例化只需其自身。
GOLDEN_SRCS = $(GOLDEN_RTL)/VirtualLoadQueue.sv

# FM：golden 顶层 VirtualLoadQueue（纯叶子）vs 手写同名 wrapper（→ 可读核）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/VirtualLoadQueue_wrapper.sv
FM_VARIANTS = VirtualLoadQueue

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
