MODULE = AXI4IdIndexer_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/AXI4IdIndexer.sv \
           $(RTL_DIR)/uncore/AXI4IdIndexer_1.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4IdIndexer_1.sv
FM_VARIANTS = AXI4IdIndexer_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
