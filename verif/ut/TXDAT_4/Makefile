MODULE = TXDAT_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXDAT_4.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXDAT_4_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/TXDAT_4.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXDAT_4
FM_REF_DEPS_TXDAT_4 = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
