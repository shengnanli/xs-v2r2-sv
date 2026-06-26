MODULE = CLINT

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/clint_pkg.sv \
           $(RTL_DIR)/uncore/CLINT.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CLINT.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/CLINT_wrapper.sv
FM_VARIANTS = CLINT

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
