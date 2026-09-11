MODULE = TXSNP

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXSNP.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TXSNP = 
GOLDEN_SRCS = $(GOLDEN_RTL)/TXSNP.sv
FM_VARIANTS = TXSNP

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
