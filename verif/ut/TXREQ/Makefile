MODULE = TXREQ

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXREQ.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXREQ_wrapper.sv $(GOLDEN_RTL)/Queue16_CHIREQ.sv $(GOLDEN_RTL)/ram_16x137.sv

# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): Queue16_CHIREQ.sv, ram_16x137.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXREQ.sv $(GOLDEN_RTL)/Queue16_CHIREQ.sv $(GOLDEN_RTL)/ram_16x137.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXREQ
FM_REF_DEPS_TXREQ = Queue16_CHIREQ.sv ram_16x137.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
