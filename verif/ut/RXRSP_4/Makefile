MODULE = RXRSP_4

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RXRSP_4.sv
TB_SRCS = tb.sv

FM_REF_DEPS_RXRSP_4 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/RXRSP_4.sv
FM_VARIANTS = RXRSP_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
