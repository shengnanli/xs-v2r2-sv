MODULE = MbistPipeL2Prefetcher

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 xs_MbistPipeL2Prefetcher_core(无子模块, 无厂商宏)。
RTL_SRCS = $(RTL_DIR)/l2/MbistPipeL2Prefetcher.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/MbistPipeL2Prefetcher_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MbistPipeL2Prefetcher.sv
# UT 变体: impl 顶层改名 MbistPipeL2Prefetcher_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict, 无依赖(自包含 MBIST 分发级)。
FM_VARIANTS = MbistPipeL2Prefetcher

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
