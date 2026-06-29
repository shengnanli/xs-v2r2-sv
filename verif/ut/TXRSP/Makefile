MODULE = TXRSP

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXRSP.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXRSP_wrapper.sv $(GOLDEN_RTL)/Queue16_CHIRSP.sv $(GOLDEN_RTL)/ram_16x62.sv

# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): Queue16_CHIRSP.sv, ram_16x62.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXRSP.sv $(GOLDEN_RTL)/Queue16_CHIRSP.sv $(GOLDEN_RTL)/ram_16x62.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXRSP
FM_REF_DEPS_TXRSP = Queue16_CHIRSP.sv ram_16x62.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
