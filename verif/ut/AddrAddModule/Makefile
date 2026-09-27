MODULE = AddrAddModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/AddrAddModule.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/AddrAddModule.sv

FM_VARIANTS = AddrAddModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
