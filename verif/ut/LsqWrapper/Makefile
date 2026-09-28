MODULE = LsqWrapper

# LsqWrapper（访存队列最外层）。golden 直接 child 2 个：LoadQueue（本 lane 签核）、StoreQueue
# （PROVEN_DIRECT），连同全部子孙件。处置 = **两侧白盒**：ref 读 golden 整棵子树，impl 读本仓
# 重写件整棵子树，无黑盒。本层胶水见 rtl/memblock/LsqWrapper.sv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LsqWrapper.sv $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/common/DelayN_225.sv $(RTL_DIR)/common/DelayN_297.sv \
           $(RTL_DIR)/common/DelayNWithValid_103.sv $(RTL_DIR)/common/DelayNWithValid_148.sv \
           $(RTL_DIR)/common/DelayNWithValid_149.sv $(RTL_DIR)/common/DelayNWithValid_152.sv \
           $(RTL_DIR)/common/DelayNWithValid_155.sv $(RTL_DIR)/common/DelayNWithValid_4.sv \
           $(RTL_DIR)/common/DelayNWithValid_52.sv $(RTL_DIR)/common/DelayNWithValid_55.sv \
           $(RTL_DIR)/common/DelayNWithValid_7.sv $(RTL_DIR)/common/RRArbiterInit_11.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv $(RTL_DIR)/memblock/AgeDetector_38.sv \
           $(RTL_DIR)/memblock/DatamoduleResultBuffer.sv $(RTL_DIR)/memblock/FreeList_3.sv \
           $(RTL_DIR)/memblock/FreeList_4.sv $(RTL_DIR)/memblock/FreeList_5.sv \
           $(RTL_DIR)/memblock/FreeList_6.sv $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/LoadQueueRAR.sv $(RTL_DIR)/memblock/LoadQueueRAW.sv \
           $(RTL_DIR)/memblock/LoadQueueReplay.sv $(RTL_DIR)/memblock/LoadQueue.sv \
           $(RTL_DIR)/memblock/LoadQueueUncache.sv $(RTL_DIR)/memblock/LqExceptionBuffer.sv \
           $(RTL_DIR)/memblock/LqMaskModule.sv $(RTL_DIR)/memblock/LqPAddrModule_1.sv \
           $(RTL_DIR)/memblock/LqPAddrModule.sv $(RTL_DIR)/memblock/LqVAddrModule.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_1.sv $(RTL_DIR)/memblock/PipelineRegModule_2.sv \
           $(RTL_DIR)/memblock/PipelineRegModule.sv $(RTL_DIR)/memblock/SQAddrModule_1.sv \
           $(RTL_DIR)/memblock/SQAddrModule.sv $(RTL_DIR)/memblock/SQData8Module.sv \
           $(RTL_DIR)/memblock/SQDataModule.sv $(RTL_DIR)/memblock/StoreExceptionBuffer.sv \
           $(RTL_DIR)/memblock/StoreQueue.sv $(RTL_DIR)/memblock/UncacheEntry_10.sv \
           $(RTL_DIR)/memblock/UncacheEntry_11.sv $(RTL_DIR)/memblock/UncacheEntry_12.sv \
           $(RTL_DIR)/memblock/UncacheEntry_13.sv $(RTL_DIR)/memblock/UncacheEntry_14.sv \
           $(RTL_DIR)/memblock/UncacheEntry_15.sv $(RTL_DIR)/memblock/UncacheEntry_1.sv \
           $(RTL_DIR)/memblock/UncacheEntry_2.sv $(RTL_DIR)/memblock/UncacheEntry_3.sv \
           $(RTL_DIR)/memblock/UncacheEntry_4.sv $(RTL_DIR)/memblock/UncacheEntry_5.sv \
           $(RTL_DIR)/memblock/UncacheEntry_6.sv $(RTL_DIR)/memblock/UncacheEntry_7.sv \
           $(RTL_DIR)/memblock/UncacheEntry_8.sv $(RTL_DIR)/memblock/UncacheEntry_9.sv \
           $(RTL_DIR)/memblock/UncacheEntry.sv $(RTL_DIR)/memblock/VirtualLoadQueue.sv \
           $(RTL_DIR)/memblock/xs_LqRawDataCam_core.sv $(RTL_DIR)/memblock/xs_UncacheEntry_core.sv

LSQ_CHILDREN = AgeDetector_38.sv DatamoduleResultBuffer.sv DelayN_13.sv DelayN_225.sv DelayN_297.sv \
               DelayNWithValid_103.sv DelayNWithValid_148.sv DelayNWithValid_149.sv \
               DelayNWithValid_152.sv DelayNWithValid_155.sv DelayNWithValid_4.sv DelayNWithValid_52.sv \
               DelayNWithValid_55.sv DelayNWithValid_7.sv FreeList_3.sv FreeList_4.sv FreeList_5.sv \
               FreeList_6.sv LoadQueue.sv LoadQueueRAR.sv LoadQueueRAW.sv LoadQueueReplay.sv \
               LoadQueueUncache.sv LqExceptionBuffer.sv LqMaskModule.sv LqPAddrModule.sv \
               LqPAddrModule_1.sv LqVAddrModule.sv PipelineRegModule.sv PipelineRegModule_1.sv \
               PipelineRegModule_2.sv RRArbiterInit_11.sv SQAddrModule.sv SQAddrModule_1.sv \
               SQData8Module.sv SQDataModule.sv StoreExceptionBuffer.sv StoreQueue.sv UncacheEntry.sv \
               UncacheEntry_1.sv UncacheEntry_10.sv UncacheEntry_11.sv UncacheEntry_12.sv \
               UncacheEntry_13.sv UncacheEntry_14.sv UncacheEntry_15.sv UncacheEntry_2.sv \
               UncacheEntry_3.sv UncacheEntry_4.sv UncacheEntry_5.sv UncacheEntry_6.sv UncacheEntry_7.sv \
               UncacheEntry_8.sv UncacheEntry_9.sv VirtualLoadQueue.sv
TB_SRCS  = tb.sv

# ★逐个写字面 .sv 名，别用 $(addsuffix ...)★：scripts/fm_passing_model.py 只认字面 .sv 词。
GOLDEN_SRCS = $(GOLDEN_RTL)/LsqWrapper.sv $(addprefix $(GOLDEN_RTL)/,$(LSQ_CHILDREN))

FM_VARIANTS = LsqWrapper
FM_REF_DEPS_LsqWrapper = $(LSQ_CHILDREN)

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lsq.py --check
