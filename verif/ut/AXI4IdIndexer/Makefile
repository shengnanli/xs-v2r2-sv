MODULE = AXI4IdIndexer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/AXI4IdIndexer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4IdIndexer.sv
FM_VARIANTS = AXI4IdIndexer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
