MODULE = ImmExtractor

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ImmExtractor.sv \
           $(RTL_DIR)/backend/ImmExtractor_12.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ImmExtractor.sv $(GOLDEN_RTL)/ImmExtractor_12.sv
FM_VARIANTS = ImmExtractor ImmExtractor_12

include ../../../scripts/ut_common.mk

# golden 叶子无随机初始化,与可读核对齐。
VCS += +define+SYNTHESIS
