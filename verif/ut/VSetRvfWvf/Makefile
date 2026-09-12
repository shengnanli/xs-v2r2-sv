MODULE = VSetRvfWvf

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VSetRvfWvf.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# VsetModule 是 vset 运算叶子（G1 与 G0 逐字一致）：两侧同源 elaborate，无黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/VSetRvfWvf.sv $(GOLDEN_RTL)/VsetModule.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/VsetModule.sv

FM_VARIANTS = VSetRvfWvf
FM_REF_DEPS_VSetRvfWvf = VsetModule.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
