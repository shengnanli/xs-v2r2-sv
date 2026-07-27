# 自动生成: scripts/gen_arbiter8.py —— 勿手改
MODULE = Arbiter8_CHIDAT

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS = $(RTL_DIR)/l2/arbiter8_pkg.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/Arbiter8_CHIDAT_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter8_CHIDAT.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = Arbiter8_CHIDAT
# 纯组合叶子, 无子例化/无黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
