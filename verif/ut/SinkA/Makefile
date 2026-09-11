MODULE = SinkA

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SinkA.sv
TB_SRCS = tb.sv

FM_REF_DEPS_SinkA = 
GOLDEN_SRCS = $(GOLDEN_RTL)/SinkA.sv
FM_VARIANTS = SinkA

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
