MODULE = Decoupled2LCredit_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/Decoupled2LCredit_1.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/Decoupled2LCredit_1_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/Decoupled2LCredit_1.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = Decoupled2LCredit_1
FM_REF_DEPS_Decoupled2LCredit_1 = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
