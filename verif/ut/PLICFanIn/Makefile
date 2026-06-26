MODULE = PLICFanIn

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/plic_pkg.sv \
           $(RTL_DIR)/uncore/PLICFanIn.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PLICFanIn.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/PLICFanIn_wrapper.sv
FM_VARIANTS = PLICFanIn

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
