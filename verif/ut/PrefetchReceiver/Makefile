MODULE = PrefetchReceiver

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 xs_PrefetchReceiver_core(纯组合, 无子模块)。
RTL_SRCS = $(RTL_DIR)/l2/PrefetchReceiver.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/PrefetchReceiver_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchReceiver.sv
# UT 变体: impl 顶层改名 PrefetchReceiver_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict, 无依赖(纯组合地址切分)。
FM_VARIANTS = PrefetchReceiver

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
