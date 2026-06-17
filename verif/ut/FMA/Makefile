MODULE = FMA

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/fma_pkg.sv \
           $(RTL_DIR)/backend/FMA.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 浮点乘加阵列 FloatFMA 及其叶子（两侧 UT 共用）。
FMA_DEPS = FloatFMA.sv BoothEncoderF64F32F16.sv CSA3to2.sv CSA4to2.sv \
           CSA_Nto2With3to2MainPipeline.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FMA.sv $(addprefix $(GOLDEN_RTL)/,$(FMA_DEPS))

WRAPPER_SRCS = $(RTL_DIR)/backend/FMA_wrapper.sv $(addprefix $(GOLDEN_RTL)/,$(FMA_DEPS))
FM_VARIANTS = FMA
FM_REF_DEPS_FMA = $(FMA_DEPS)
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
