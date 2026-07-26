MODULE = L2Cache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 xs_L2Cache_core(无子模块, 无厂商宏, REPLACEMENT 真逻辑)。
RTL_SRCS = $(RTL_DIR)/l2/L2Cache.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/L2Cache_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2Cache.sv
# UT 变体: impl 顶层改名 L2Cache_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict, 无依赖(自包含 MBIST 分发级, 0 子模块 0 黑盒)。
FM_VARIANTS = L2Cache

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
