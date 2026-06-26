MODULE = L2Slice

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mbist_pipe_pkg.sv \
           $(RTL_DIR)/uncore/mbist_pipe_ctrl.sv \
           $(RTL_DIR)/uncore/L2Slice.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Slice.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/L2Slice_wrapper.sv
FM_VARIANTS = L2Slice

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
