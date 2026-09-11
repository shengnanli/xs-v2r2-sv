MODULE = CHILogger

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/CHILogger.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CHILogger.sv
FM_REF_DEPS_CHILogger = 
FM_VARIANTS = CHILogger

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
