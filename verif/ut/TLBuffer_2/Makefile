# 自动生成：scripts/gen_tlbuffer2.py —— 勿手改
MODULE = TLBuffer_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer2_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_2.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_2.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_2.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_3.sv \
              $(GOLDEN_RTL)/ram_2x127.sv \
              $(GOLDEN_RTL)/ram_2x90.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_2_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer2_queue_blackbox.sv
FM_VARIANTS = TLBuffer_2
# FM: ref = golden TLBuffer_2.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
