MODULE = TLLogger

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TLLogger.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TLLogger = 
GOLDEN_SRCS = $(GOLDEN_RTL)/TLLogger.sv
FM_VARIANTS = TLLogger

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
