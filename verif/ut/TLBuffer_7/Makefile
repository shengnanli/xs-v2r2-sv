MODULE = TLBuffer_7

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer_7.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleA_7.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleB.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleC.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleD_8.sv \
           $(GOLDEN_RTL)/Queue2_TLBundleE.sv \
           $(GOLDEN_RTL)/ram_2x284.sv \
           $(GOLDEN_RTL)/ram_2x309.sv \
           $(GOLDEN_RTL)/ram_2x373.sv \
           $(GOLDEN_RTL)/ram_2x406.sv \
           $(GOLDEN_RTL)/ram_sink_2x10.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TLBuffer_7 = Queue2_TLBundleA_7.sv Queue2_TLBundleD_8.sv Queue2_TLBundleB.sv Queue2_TLBundleC.sv Queue2_TLBundleE.sv ram_2x406.sv ram_2x284.sv ram_2x309.sv ram_2x373.sv ram_sink_2x10.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_7.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_7.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_8.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE.sv \
              $(GOLDEN_RTL)/ram_2x406.sv \
              $(GOLDEN_RTL)/ram_2x284.sv \
              $(GOLDEN_RTL)/ram_2x309.sv \
              $(GOLDEN_RTL)/ram_2x373.sv \
              $(GOLDEN_RTL)/ram_sink_2x10.sv
FM_VARIANTS = TLBuffer_7

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
