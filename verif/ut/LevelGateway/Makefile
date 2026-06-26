MODULE = LevelGateway

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/LevelGateway.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LevelGateway.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/LevelGateway_wrapper.sv
FM_VARIANTS = LevelGateway

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
