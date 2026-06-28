# 自动生成：scripts/gen_tlbuffer6.py —— 勿手改
MODULE = TLBuffer_6

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer6_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_6.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_6.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
              $(GOLDEN_RTL)/ram_2x355.sv \
              $(GOLDEN_RTL)/ram_2x280.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_6_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer6_queue_blackbox.sv
FM_VARIANTS = TLBuffer_6
# FM: ref = golden TLBuffer_6.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
