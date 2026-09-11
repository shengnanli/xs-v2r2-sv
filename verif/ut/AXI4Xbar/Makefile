MODULE = AXI4Xbar

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/AXI4Xbar.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_UInt2.sv \
                  $(GOLDEN_RTL)/ram_2x2.sv

FM_REF_DEPS_AXI4Xbar = Queue2_UInt2.sv ram_2x2.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Xbar.sv
FM_VARIANTS = AXI4Xbar

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
