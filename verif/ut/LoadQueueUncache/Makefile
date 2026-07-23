MODULE = LoadQueueUncache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/loadqueueuncache_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueueUncache.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SUBS = $(GOLDEN_RTL)/UncacheEntry.sv $(GOLDEN_RTL)/UncacheEntry_1.sv $(GOLDEN_RTL)/UncacheEntry_2.sv $(GOLDEN_RTL)/UncacheEntry_3.sv $(GOLDEN_RTL)/FreeList_6.sv $(GOLDEN_RTL)/RRArbiterInit_9.sv $(GOLDEN_RTL)/PipelineRegModule.sv $(GOLDEN_RTL)/PipelineRegModule_1.sv $(GOLDEN_RTL)/PipelineRegModule_2.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueUncache.sv $(GOLDEN_SUBS)

# INLINE(FM诊断: FreeList_6黑盒致golden io_empty undriven cut-point失配)。impl复用golden
# 子模块, 两侧链入GOLDEN_SUBS(FreeList_6/UncacheEntry/RRArbiter/PipelineReg)→io_empty可比。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueUncache_wrapper.sv $(GOLDEN_SUBS)
FM_VARIANTS = LoadQueueUncache
FM_REF_DEPS_LoadQueueUncache = UncacheEntry.sv UncacheEntry_1.sv UncacheEntry_2.sv UncacheEntry_3.sv FreeList_6.sv RRArbiterInit_9.sv PipelineRegModule.sv PipelineRegModule_1.sv PipelineRegModule_2.sv
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/memblock
