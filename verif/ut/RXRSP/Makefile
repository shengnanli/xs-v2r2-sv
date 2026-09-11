MODULE = RXRSP

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RXRSP.sv
TB_SRCS = tb.sv

FM_REF_DEPS_RXRSP = 
GOLDEN_SRCS = $(GOLDEN_RTL)/RXRSP.sv
FM_VARIANTS = RXRSP

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
