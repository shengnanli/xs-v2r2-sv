# TopDownMonitor UT + FM Makefile
MODULE = TopDownMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS =
WRAPPER_SRCS = $(RTL_DIR)/l2/TopDownMonitor_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TopDownMonitor.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TopDownMonitor
# 纯组合叶子, 无子例化/无黑盒。golden 含悬空性能计数器 dead cone(不驱动输出)。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
