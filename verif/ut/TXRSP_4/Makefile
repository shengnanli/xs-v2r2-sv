MODULE = TXRSP_4

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXRSP_4.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TXRSP_4 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/TXRSP_4.sv
FM_VARIANTS = TXRSP_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
