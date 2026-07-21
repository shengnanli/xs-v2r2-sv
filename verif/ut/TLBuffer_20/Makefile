# 自动生成：scripts/gen_tlbuffer20.py —— 勿手改
MODULE = TLBuffer_20

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer20_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer_20.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: 两侧共用真实 Queue2 + ram 叶子。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
              $(GOLDEN_RTL)/ram_2x115.sv \
              $(GOLDEN_RTL)/ram_2x78.sv

# INLINE(裁定option2): 消Queue2黑盒桩, 两侧链真实golden Queue2+全部ram, strict整体证
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_20_wrapper.sv \
               $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv \
               $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
               $(GOLDEN_RTL)/ram_2x115.sv \
               $(GOLDEN_RTL)/ram_2x78.sv
FM_REF_DEPS_TLBuffer_20 = Queue2_TLBundleA_10.sv Queue2_TLBundleD_11.sv ram_2x115.sv ram_2x78.sv
FM_VARIANTS = TLBuffer_20
# FM: ref = golden TLBuffer_20.sv (Queue 自动黑盒); impl = pkg + 可读核 + wrapper + 黑盒声明。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
