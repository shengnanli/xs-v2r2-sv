MODULE = TLXbar_3

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TLXbar_3.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_3.sv
FM_VARIANTS = TLXbar_3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
