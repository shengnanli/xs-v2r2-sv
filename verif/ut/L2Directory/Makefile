MODULE = L2Directory

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/L2Directory.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Directory.sv
FM_VARIANTS = L2Directory

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
