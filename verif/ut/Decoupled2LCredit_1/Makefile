MODULE = Decoupled2LCredit_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/Decoupled2LCredit_1.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Decoupled2LCredit_1 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/Decoupled2LCredit_1.sv
FM_VARIANTS = Decoupled2LCredit_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
