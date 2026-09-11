MODULE = WbFuBusyTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/WbFuBusyTable.sv
TB_SRCS = tb.sv

FM_REF_DEPS_WbFuBusyTable = 
GOLDEN_SRCS = $(GOLDEN_RTL)/WbFuBusyTable.sv
FM_VARIANTS = WbFuBusyTable

include ../../../scripts/ut_common.mk

# 纯组合无随机初始化; 关 SYNTHESIS 以与可读核对齐(golden 无断言)。
VCS += +define+SYNTHESIS
