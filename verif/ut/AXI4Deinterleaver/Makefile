MODULE = AXI4Deinterleaver

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/AXI4Deinterleaver.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_AXI4BundleR_3.sv \
                  $(GOLDEN_RTL)/ram_2x264.sv

FM_REF_DEPS_AXI4Deinterleaver = Queue2_AXI4BundleR_3.sv ram_2x264.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Deinterleaver.sv
FM_VARIANTS = AXI4Deinterleaver

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
