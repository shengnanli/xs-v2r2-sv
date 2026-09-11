MODULE = RXREQ

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RXREQ.sv
TB_SRCS = tb.sv

FM_REF_DEPS_RXREQ = 
GOLDEN_SRCS = $(GOLDEN_RTL)/RXREQ.sv
FM_VARIANTS = RXREQ

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
