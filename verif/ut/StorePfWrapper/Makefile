MODULE = StorePfWrapper

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/storepfwrapper_pkg.sv \
           $(RTL_DIR)/memblock/StorePfWrapper.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/StorePfWrapper_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StorePfWrapper.sv \
              $(GOLDEN_RTL)/Serializer.sv \
              $(GOLDEN_RTL)/StorePrefetchBursts.sv \
              $(GOLDEN_RTL)/PrefetchBurstGenerator.sv \
              $(GOLDEN_RTL)/Arbiter2_StorePrefetchReq.sv

TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = StorePfWrapper
# FM 只证明 wrapper 连接逻辑；Serializer / StorePrefetchBursts 在 ref/impl 两侧同名黑盒。
FM_REF_DEPS_StorePfWrapper =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
