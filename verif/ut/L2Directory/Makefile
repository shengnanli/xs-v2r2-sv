MODULE = L2Directory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mbist_pipe_pkg.sv \
           $(RTL_DIR)/uncore/mbist_pipe_ctrl.sv \
           $(RTL_DIR)/uncore/L2Directory.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Directory.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/L2Directory_wrapper.sv
FM_VARIANTS = L2Directory

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
