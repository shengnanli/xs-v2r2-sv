MODULE = StorePfWrapper

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/storepfwrapper_pkg.sv \
           $(RTL_DIR)/memblock/StorePfWrapper.sv

# INLINE(裁定option2 pilot验证): 两侧链真实golden子模块, 消Serializer/StorePrefetchBursts黑盒
WRAPPER_SRCS = $(RTL_DIR)/memblock/StorePfWrapper_wrapper.sv \
               $(GOLDEN_RTL)/Serializer.sv \
               $(GOLDEN_RTL)/StorePrefetchBursts.sv \
               $(GOLDEN_RTL)/PrefetchBurstGenerator.sv \
               $(GOLDEN_RTL)/Arbiter2_StorePrefetchReq.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StorePfWrapper.sv \
              $(GOLDEN_RTL)/Serializer.sv \
              $(GOLDEN_RTL)/StorePrefetchBursts.sv \
              $(GOLDEN_RTL)/PrefetchBurstGenerator.sv \
              $(GOLDEN_RTL)/Arbiter2_StorePrefetchReq.sv

TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = StorePfWrapper
FM_REF_DEPS_StorePfWrapper = Serializer.sv StorePrefetchBursts.sv PrefetchBurstGenerator.sv Arbiter2_StorePrefetchReq.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
