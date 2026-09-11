MODULE = TXRSP

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXRSP.sv \
           $(GOLDEN_RTL)/Queue16_CHIRSP.sv \
           $(GOLDEN_RTL)/ram_16x62.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TXRSP = Queue16_CHIRSP.sv ram_16x62.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXRSP.sv \
              $(GOLDEN_RTL)/Queue16_CHIRSP.sv \
              $(GOLDEN_RTL)/ram_16x62.sv
FM_VARIANTS = TXRSP

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
