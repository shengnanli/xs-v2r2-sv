MODULE = LevelGateway

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LevelGateway.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LevelGateway.sv
FM_VARIANTS = LevelGateway

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
