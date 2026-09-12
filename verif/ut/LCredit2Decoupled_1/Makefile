MODULE = LCredit2Decoupled_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv
TB_SRCS = tb.sv

FM_REF_DEPS_LCredit2Decoupled_1 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_1.sv
FM_VARIANTS = LCredit2Decoupled_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
