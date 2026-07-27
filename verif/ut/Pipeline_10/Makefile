MODULE = Pipeline_10

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读核 xs_Pipeline_10_core(两级级联) + 深度1队列核 xs_Queue1_UInt32_core。
RTL_SRCS = $(RTL_DIR)/l2/Pipeline_10.sv $(RTL_DIR)/l2/Queue1_UInt32.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/Pipeline_10_wrapper.sv
# golden 顶层 + 其子模块 Queue1_UInt32(ref 侧例化, 被 stages_0/1 复用)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_10.sv $(GOLDEN_RTL)/Queue1_UInt32.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; golden 侧依赖 Queue1_UInt32(ref 侧 elaborate)。两侧无死位。
FM_VARIANTS = Pipeline_10
FM_REF_DEPS_Pipeline_10 = Queue1_UInt32.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
