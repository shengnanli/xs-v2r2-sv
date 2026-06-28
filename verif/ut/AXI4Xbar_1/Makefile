# 自动生成：scripts/gen_axi4xbar1.py —— 勿手改
MODULE = AXI4Xbar_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): W 路由队列 Queue2_UInt5 及其 RAM。
RTL_SRCS = $(RTL_DIR)/uncore/axi4xbar1_pkg.sv \
           $(RTL_DIR)/uncore/AXI4Xbar_1.sv \
           $(GOLDEN_RTL)/Queue2_UInt5.sv \
           $(GOLDEN_RTL)/ram_2x5.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_UInt5/ram_2x5 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Xbar_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Xbar_1_wrapper.sv
FM_VARIANTS = AXI4Xbar_1
# FM: ref = golden AXI4Xbar_1 + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。两侧队列相同。
FM_REF_DEPS_AXI4Xbar_1 = Queue2_UInt5.sv ram_2x5.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
