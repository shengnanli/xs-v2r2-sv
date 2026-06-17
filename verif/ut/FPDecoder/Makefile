MODULE = FPDecoder

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:类型包 + 组合核(纯叶子,无黑盒子模块)。
RTL_SRCS = $(RTL_DIR)/backend/fpdecoder_pkg.sv \
           $(RTL_DIR)/backend/FPDecoder.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 纯叶子,无子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/FPDecoder.sv

# FM:golden FPDecoder vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/FPDecoder_wrapper.sv
FM_VARIANTS = FPDecoder

include ../../../scripts/ut_common.mk

# golden 无断言,关随机初始化对齐可读核(无随机)。
VCS += +define+SYNTHESIS
