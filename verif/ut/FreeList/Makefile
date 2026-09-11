MODULE = FreeList

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/FreeList.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FreeList.sv
FM_VARIANTS = FreeList

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
