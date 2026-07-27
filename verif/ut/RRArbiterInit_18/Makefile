# 自动生成：scripts/gen_fastarbiter.py —— 勿手改
MODULE = RRArbiterInit_18

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/RRArbiterInit_18.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/RRArbiterInit_18.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/RRArbiterInit_18_wrapper.sv
FM_VARIANTS = RRArbiterInit_18
# FM: ref = golden RRArbiterInit_18.sv; impl = pkg + 可读核 + wrapper。无外部依赖/黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
