MODULE = MSHRSelector

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/MSHRSelector.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRSelector.sv
FM_VARIANTS = MSHRSelector

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
