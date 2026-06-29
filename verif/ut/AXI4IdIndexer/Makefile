# 自动生成：scripts/gen_axi4idindexer.py —— 勿手改
MODULE = AXI4IdIndexer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 (两变体同在 AXI4IdIndexer.sv); 纯组合, 无黑盒依赖。
RTL_SRCS = $(RTL_DIR)/uncore/AXI4IdIndexer.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4IdIndexer.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4IdIndexer_wrapper.sv
FM_VARIANTS = AXI4IdIndexer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
