MODULE = L2Directory_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mbist_pipe_pkg.sv \
           $(RTL_DIR)/uncore/mbist_pipe_ctrl.sv \
           $(RTL_DIR)/uncore/L2Directory_var_core.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Directory_3.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/L2Directory_3_wrapper.sv
FM_VARIANTS = L2Directory_3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
