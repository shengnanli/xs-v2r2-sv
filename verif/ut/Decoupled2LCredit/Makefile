MODULE = Decoupled2LCredit

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/Decoupled2LCredit.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Decoupled2LCredit = 
GOLDEN_SRCS = $(GOLDEN_RTL)/Decoupled2LCredit.sv
FM_VARIANTS = Decoupled2LCredit

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
