MODULE = LCredit2Decoupled_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_1_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_1.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = LCredit2Decoupled_1
FM_REF_DEPS_LCredit2Decoupled_1 = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
