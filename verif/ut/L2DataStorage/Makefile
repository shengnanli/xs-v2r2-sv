MODULE = L2DataStorage

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mbist_pipe_pkg.sv \
           $(RTL_DIR)/uncore/mbist_pipe_ctrl.sv \
           $(RTL_DIR)/uncore/L2DataStorage.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2DataStorage.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/L2DataStorage_wrapper.sv
FM_VARIANTS = L2DataStorage

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
