# MbistIntfL2 UT + FM Makefile
MODULE = MbistIntfL2

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS = 
WRAPPER_SRCS = $(RTL_DIR)/l2/MbistIntfL2_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MbistIntfL2.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = MbistIntfL2
# 纯组合叶子, 无子例化/无黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
