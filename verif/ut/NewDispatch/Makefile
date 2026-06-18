MODULE = NewDispatch

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / logic / connect)。
RTL_SRCS = $(RTL_DIR)/backend/newdispatch_pkg.sv \
           $(RTL_DIR)/backend/NewDispatch.sv

TB_SRCS = variants_xs.sv tb.sv

SUB_DEPS = $(GOLDEN_RTL)/RegCacheTagTable.sv \
           $(GOLDEN_RTL)/BusyTable.sv \
           $(GOLDEN_RTL)/BusyTable_1.sv \
           $(GOLDEN_RTL)/BusyTable_2.sv \
           $(GOLDEN_RTL)/BusyTable_3.sv \
           $(GOLDEN_RTL)/VlBusyTable.sv \
           $(GOLDEN_RTL)/LsqEnqCtrl.sv \
           $(GOLDEN_RTL)/RegCacheTagModule.sv \
           $(GOLDEN_RTL)/RegCacheTagModule_1.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/NewDispatch.sv $(SUB_DEPS)

WRAPPER_SRCS = $(RTL_DIR)/backend/NewDispatch_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = NewDispatch
FM_REF_DEPS_NewDispatch = RegCacheTagTable.sv BusyTable.sv BusyTable_1.sv BusyTable_2.sv BusyTable_3.sv VlBusyTable.sv LsqEnqCtrl.sv RegCacheTagModule.sv RegCacheTagModule_1.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
