MODULE = LoadQueue

# LoadQueue（load 队列装配层）。golden 直接 child 6 个：LoadQueueRAR / LoadQueueRAW / LoadQueueReplay /
# VirtualLoadQueue / LqExceptionBuffer / LoadQueueUncache，连同全部子孙件都已签核
# （LoadQueueUncache / LqExceptionBuffer 的 receipt 在 evidence/ff3b73fa4b35、evidence/e268a54e29da；
#  其余见 docs/coverage_three_axis.tsv 的 PROVEN_DIRECT）。处置 = **两侧白盒**：
# ref 读 golden 整棵子树，impl 读本仓重写件整棵子树，无黑盒。本层胶水见 rtl/memblock/LoadQueue.sv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadQueue.sv $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/common/DelayN_225.sv $(RTL_DIR)/common/DelayN_297.sv \
           $(RTL_DIR)/common/DelayNWithValid_103.sv $(RTL_DIR)/common/DelayNWithValid_148.sv \
           $(RTL_DIR)/common/DelayNWithValid_149.sv $(RTL_DIR)/common/DelayNWithValid_152.sv \
           $(RTL_DIR)/common/DelayNWithValid_155.sv $(RTL_DIR)/common/DelayNWithValid_4.sv \
           $(RTL_DIR)/common/DelayNWithValid_52.sv $(RTL_DIR)/common/DelayNWithValid_55.sv \
           $(RTL_DIR)/common/DelayNWithValid_7.sv $(RTL_DIR)/common/RRArbiterInit_11.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv $(RTL_DIR)/memblock/AgeDetector_38.sv \
           $(RTL_DIR)/memblock/FreeList_3.sv $(RTL_DIR)/memblock/FreeList_4.sv \
           $(RTL_DIR)/memblock/FreeList_5.sv $(RTL_DIR)/memblock/FreeList_6.sv \
           $(RTL_DIR)/memblock/FreeList.sv $(RTL_DIR)/memblock/LoadQueueRAR.sv \
           $(RTL_DIR)/memblock/LoadQueueRAW.sv $(RTL_DIR)/memblock/LoadQueueReplay.sv \
           $(RTL_DIR)/memblock/LoadQueueUncache.sv $(RTL_DIR)/memblock/LqExceptionBuffer.sv \
           $(RTL_DIR)/memblock/LqMaskModule.sv $(RTL_DIR)/memblock/LqPAddrModule_1.sv \
           $(RTL_DIR)/memblock/LqPAddrModule.sv $(RTL_DIR)/memblock/LqVAddrModule.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_1.sv $(RTL_DIR)/memblock/PipelineRegModule_2.sv \
           $(RTL_DIR)/memblock/PipelineRegModule.sv $(RTL_DIR)/memblock/UncacheEntry_10.sv \
           $(RTL_DIR)/memblock/UncacheEntry_11.sv $(RTL_DIR)/memblock/UncacheEntry_12.sv \
           $(RTL_DIR)/memblock/UncacheEntry_13.sv $(RTL_DIR)/memblock/UncacheEntry_14.sv \
           $(RTL_DIR)/memblock/UncacheEntry_15.sv $(RTL_DIR)/memblock/UncacheEntry_1.sv \
           $(RTL_DIR)/memblock/UncacheEntry_2.sv $(RTL_DIR)/memblock/UncacheEntry_3.sv \
           $(RTL_DIR)/memblock/UncacheEntry_4.sv $(RTL_DIR)/memblock/UncacheEntry_5.sv \
           $(RTL_DIR)/memblock/UncacheEntry_6.sv $(RTL_DIR)/memblock/UncacheEntry_7.sv \
           $(RTL_DIR)/memblock/UncacheEntry_8.sv $(RTL_DIR)/memblock/UncacheEntry_9.sv \
           $(RTL_DIR)/memblock/UncacheEntry.sv $(RTL_DIR)/memblock/VirtualLoadQueue.sv \
           $(RTL_DIR)/memblock/xs_LqRawDataCam_core.sv $(RTL_DIR)/memblock/xs_UncacheEntry_core.sv

LQ_CHILDREN = AgeDetector_38.sv DelayN_13.sv DelayN_225.sv DelayN_297.sv DelayNWithValid_103.sv \
              DelayNWithValid_148.sv DelayNWithValid_149.sv DelayNWithValid_152.sv \
              DelayNWithValid_155.sv DelayNWithValid_4.sv DelayNWithValid_52.sv DelayNWithValid_55.sv \
              DelayNWithValid_7.sv FreeList_3.sv FreeList_4.sv FreeList_5.sv FreeList_6.sv \
              LoadQueueRAR.sv LoadQueueRAW.sv LoadQueueReplay.sv LoadQueueUncache.sv \
              LqExceptionBuffer.sv LqMaskModule.sv LqPAddrModule.sv LqPAddrModule_1.sv LqVAddrModule.sv \
              PipelineRegModule.sv PipelineRegModule_1.sv PipelineRegModule_2.sv RRArbiterInit_11.sv \
              UncacheEntry.sv UncacheEntry_1.sv UncacheEntry_10.sv UncacheEntry_11.sv UncacheEntry_12.sv \
              UncacheEntry_13.sv UncacheEntry_14.sv UncacheEntry_15.sv UncacheEntry_2.sv \
              UncacheEntry_3.sv UncacheEntry_4.sv UncacheEntry_5.sv UncacheEntry_6.sv UncacheEntry_7.sv \
              UncacheEntry_8.sv UncacheEntry_9.sv VirtualLoadQueue.sv
TB_SRCS  = tb.sv

# ★逐个写字面 .sv 名，别用 $(addsuffix ...)★：scripts/fm_passing_model.py 只认字面 .sv 词。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueue.sv $(addprefix $(GOLDEN_RTL)/,$(LQ_CHILDREN))

FM_VARIANTS = LoadQueue
FM_REF_DEPS_LoadQueue = $(LQ_CHILDREN)

# 逐个比较，不合并重复寄存器（子队列里有值恒等的多份打拍；fm_predict 模型严格适用）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_lsq.py --check
