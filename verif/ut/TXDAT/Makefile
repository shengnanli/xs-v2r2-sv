MODULE = TXDAT

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXDAT.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXDAT_wrapper.sv $(GOLDEN_RTL)/Queue16_TaskBundle.sv $(GOLDEN_RTL)/ram_16x67.sv $(GOLDEN_RTL)/Queue16_DSBeat.sv $(GOLDEN_RTL)/ram_data_16x256.sv

# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): Queue16_TaskBundle.sv, ram_16x67.sv, Queue16_DSBeat.sv, ram_data_16x256.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXDAT.sv $(GOLDEN_RTL)/Queue16_TaskBundle.sv $(GOLDEN_RTL)/ram_16x67.sv $(GOLDEN_RTL)/Queue16_DSBeat.sv $(GOLDEN_RTL)/ram_data_16x256.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXDAT
FM_REF_DEPS_TXDAT = Queue16_TaskBundle.sv ram_16x67.sv Queue16_DSBeat.sv ram_data_16x256.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
