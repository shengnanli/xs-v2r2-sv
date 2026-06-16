MODULE = LoadQueueUncache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/loadqueueuncache_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueueUncache.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SUBS = $(GOLDEN_RTL)/UncacheEntry.sv $(GOLDEN_RTL)/UncacheEntry_1.sv $(GOLDEN_RTL)/UncacheEntry_2.sv $(GOLDEN_RTL)/UncacheEntry_3.sv $(GOLDEN_RTL)/FreeList_6.sv $(GOLDEN_RTL)/RRArbiterInit_9.sv $(GOLDEN_RTL)/PipelineRegModule.sv $(GOLDEN_RTL)/PipelineRegModule_1.sv $(GOLDEN_RTL)/PipelineRegModule_2.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueUncache.sv $(GOLDEN_SUBS)

WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueUncache_wrapper.sv
FM_VARIANTS = LoadQueueUncache
FM_REF_DEPS_LoadQueueUncache =
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/memblock
