# 自动生成：scripts/gen_tlbuffer8.py —— 勿手改
MODULE = TLBuffer_8

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer8_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_8.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_8.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_14.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
              $(GOLDEN_RTL)/ram_2x134.sv \
              $(GOLDEN_RTL)/ram_2x77.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_8_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer8_queue_blackbox.sv
FM_VARIANTS = TLBuffer_8
# FM: ref = golden TLBuffer_8.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
