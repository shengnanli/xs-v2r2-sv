# 自动生成：scripts/gen_tlbuffer13.py —— 勿手改
MODULE = TLBuffer_13

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer13_pkg.sv \
           $(RTL_DIR)/memblock/xs_tlbuffer13_bank.sv \
           $(RTL_DIR)/memblock/TLBuffer_13.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv \
              $(GOLDEN_RTL)/ram_2x119.sv \
              $(GOLDEN_RTL)/ram_2x352.sv \
              $(GOLDEN_RTL)/ram_2x321.sv \
              $(GOLDEN_RTL)/ram_2x283.sv \
              $(GOLDEN_RTL)/ram_sink_2x8.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_13_wrapper.sv \
               $(RTL_DIR)/memblock/tlbuffer13_queue_blackbox.sv
FM_VARIANTS = TLBuffer_13
# FM: ref = golden TLBuffer_13.sv (Queue 自动黑盒); impl = pkg + bank + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
