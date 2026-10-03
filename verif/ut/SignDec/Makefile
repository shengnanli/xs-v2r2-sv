MODULE = SignDec

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/SignDec.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/SignDec.sv

FM_VARIANTS = SignDec

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
