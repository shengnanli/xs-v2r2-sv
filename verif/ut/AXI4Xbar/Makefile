# 自动生成：scripts/gen_axi4xbar.py —— 勿手改
MODULE = AXI4Xbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): AW/W 同步队列 Queue2_UInt2 及其 RAM ram_2x2。
RTL_SRCS = $(RTL_DIR)/uncore/axi4xbar_pkg.sv \
           $(RTL_DIR)/uncore/AXI4Xbar.sv \
           $(GOLDEN_RTL)/Queue2_UInt2.sv \
           $(GOLDEN_RTL)/ram_2x2.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_UInt2/ram_2x2 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Xbar.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Xbar_wrapper.sv
FM_VARIANTS = AXI4Xbar
# FM: ref = golden AXI4Xbar + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。两侧队列相同。
FM_REF_DEPS_AXI4Xbar = Queue2_UInt2.sv ram_2x2.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
