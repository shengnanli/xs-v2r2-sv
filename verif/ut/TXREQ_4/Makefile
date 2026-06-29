MODULE = TXREQ_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXREQ_4.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXREQ_4_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/TXREQ_4.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXREQ_4
FM_REF_DEPS_TXREQ_4 = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
