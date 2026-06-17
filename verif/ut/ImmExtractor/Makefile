MODULE = ImmExtractor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:类型包 + 组合核(纯叶子)。
RTL_SRCS = $(RTL_DIR)/backend/immextractor_pkg.sv \
           $(RTL_DIR)/backend/ImmExtractor.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 两个变体(纯叶子,无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/ImmExtractor.sv $(GOLDEN_RTL)/ImmExtractor_12.sv

# FM:对两个 golden 变体各做一次等价比对。
WRAPPER_SRCS = $(RTL_DIR)/backend/ImmExtractor_wrapper.sv \
               $(RTL_DIR)/backend/ImmExtractor_12_wrapper.sv
FM_VARIANTS = ImmExtractor ImmExtractor_12
# 两变体均为纯叶子,无 golden 侧依赖文件。

include ../../../scripts/ut_common.mk

# golden 叶子无随机初始化,与可读核对齐。
VCS += +define+SYNTHESIS
