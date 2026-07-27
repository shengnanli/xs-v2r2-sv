# Arbiter4_L2ToL1Hint UT + FM Makefile
MODULE = Arbiter4_L2ToL1Hint

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS = $(RTL_DIR)/l2/arbiter4_pkg.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/Arbiter4_L2ToL1Hint_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter4_L2ToL1Hint.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = Arbiter4_L2ToL1Hint
# 纯组合叶子, 无子例化/无黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
