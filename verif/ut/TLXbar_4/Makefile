MODULE = TLXbar_4

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TLXbar_4.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_4.sv
FM_VARIANTS = TLXbar_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
