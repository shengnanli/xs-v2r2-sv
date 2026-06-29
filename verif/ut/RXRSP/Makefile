MODULE = RXRSP

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/RXRSP.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/RXRSP_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/RXRSP.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RXRSP
FM_REF_DEPS_RXRSP = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
