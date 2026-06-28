# 自动生成：scripts/gen_tlbuffer7.py —— 勿手改
MODULE = TLBuffer_7

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer7_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_7.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
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

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_7_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer7_queue_blackbox.sv
FM_VARIANTS = TLBuffer_7
# FM: ref = golden TLBuffer_7.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
