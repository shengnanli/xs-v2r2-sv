MODULE = RXDAT

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RXDAT.sv
TB_SRCS = tb.sv

FM_REF_DEPS_RXDAT = 
GOLDEN_SRCS = $(GOLDEN_RTL)/RXDAT.sv
FM_VARIANTS = RXDAT

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
