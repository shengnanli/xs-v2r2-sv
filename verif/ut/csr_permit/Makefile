MODULE = IndirectCSRPermitModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IndirectCSRPermitModule.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/IndirectCSRPermitModule.sv
FM_VARIANTS = IndirectCSRPermitModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)
