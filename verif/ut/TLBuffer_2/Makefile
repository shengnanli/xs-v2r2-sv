MODULE = TLBuffer_2

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer_2.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleA_2.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleD_3.sv \
           $(GOLDEN_RTL)/ram_2x127.sv \
           $(GOLDEN_RTL)/ram_2x90.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TLBuffer_2 = Queue2_TLBundleA_2.sv Queue2_TLBundleD_3.sv ram_2x127.sv ram_2x90.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_2.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_2.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_3.sv \
              $(GOLDEN_RTL)/ram_2x127.sv \
              $(GOLDEN_RTL)/ram_2x90.sv
FM_VARIANTS = TLBuffer_2

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
