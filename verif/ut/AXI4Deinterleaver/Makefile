# 自动生成：scripts/gen_axi4deint.py —— 勿手改
MODULE = AXI4Deinterleaver

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): 每 ID 一个深度 2 的 R 队列 Queue2_AXI4BundleR_3
# (其内部存储是 golden 行为级 RAM ram_2x264)。
RTL_SRCS = $(RTL_DIR)/uncore/axi4deint_pkg.sv \
           $(RTL_DIR)/uncore/AXI4Deinterleaver.sv \
           $(GOLDEN_RTL)/Queue2_AXI4BundleR_3.sv \
           $(GOLDEN_RTL)/ram_2x264.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_AXI4BundleR_3 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Deinterleaver.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Deinterleaver_wrapper.sv
FM_VARIANTS = AXI4Deinterleaver
# FM: ref = golden AXI4Deinterleaver + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。
FM_REF_DEPS_AXI4Deinterleaver = Queue2_AXI4BundleR_3.sv ram_2x264.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
