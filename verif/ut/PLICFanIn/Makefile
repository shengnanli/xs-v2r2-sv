MODULE = PLICFanIn

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/PLICFanIn.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PLICFanIn.sv
FM_VARIANTS = PLICFanIn

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
