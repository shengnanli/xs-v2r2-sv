# 自动生成：scripts/gen_tlbuffer15.py —— 勿手改
MODULE = TLBuffer_15

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer15_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_15.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_15.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv \
              $(GOLDEN_RTL)/ram_2x131.sv \
              $(GOLDEN_RTL)/ram_2x76.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_15_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer15_queue_blackbox.sv
FM_VARIANTS = TLBuffer_15
# FM: ref = golden TLBuffer_15.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
