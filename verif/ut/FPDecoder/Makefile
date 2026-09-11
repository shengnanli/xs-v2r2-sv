MODULE = FPDecoder

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FPDecoder.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FPDecoder.sv
FM_VARIANTS = FPDecoder

include ../../../scripts/ut_common.mk

# golden 无断言,关随机初始化对齐可读核(无随机)。
VCS += +define+SYNTHESIS
