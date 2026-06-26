MODULE = MSHRSelector

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mshrselector_pkg.sv \
           $(RTL_DIR)/uncore/MSHRSelector.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRSelector.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHRSelector_wrapper.sv
FM_VARIANTS = MSHRSelector

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
