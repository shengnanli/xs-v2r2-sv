MODULE = TLBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleA.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleD.sv \
           $(GOLDEN_RTL)/ram_2x153.sv \
           $(GOLDEN_RTL)/ram_2x90.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TLBuffer = Queue2_TLBundleA.sv Queue2_TLBundleD.sv ram_2x153.sv ram_2x90.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD.sv \
              $(GOLDEN_RTL)/ram_2x153.sv \
              $(GOLDEN_RTL)/ram_2x90.sv
FM_VARIANTS = TLBuffer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
