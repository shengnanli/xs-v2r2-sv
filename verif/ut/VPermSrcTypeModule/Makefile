MODULE = VPermSrcTypeModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VPermSrcTypeModule.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VPermSrcTypeModule.sv

FM_VARIANTS = VPermSrcTypeModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
