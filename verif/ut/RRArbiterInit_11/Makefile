# 自动生成: scripts/gen_queue1.py —— 勿手改
MODULE = RRArbiterInit_11

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读核 xs_RRArbiterInit_11_core (RTL_SRCS, UT+FM 共用) + FM impl 顶层 wrapper
# module RRArbiterInit_11 (WRAPPER_SRCS, 仅 FM 例化核; UT 用 variants_xs.sv 的 _xs 顶层)。
# 8 输入 round-robin 仲裁器, 无黑盒。
RTL_SRCS = $(RTL_DIR)/uncore/RRArbiterInit_11.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/RRArbiterInit_11_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RRArbiterInit_11.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RRArbiterInit_11

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
