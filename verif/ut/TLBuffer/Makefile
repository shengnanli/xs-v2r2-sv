MODULE = TLBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD.sv \
              $(GOLDEN_RTL)/ram_2x153.sv \
              $(GOLDEN_RTL)/ram_2x90.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer_queue_blackbox.sv
FM_VARIANTS = TLBuffer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
