MODULE = LoadQueueUncache

# LoadQueueUncache（uncache MMIO/NC load 的缓冲与发射）。golden 直接 child 23 个实例 / 21 种：
#   UncacheEntry / _1 .. _15（16 条目；rtl/memblock/xs_UncacheEntry_core.sv 家族核 + 16 个薄 wrapper）
#   FreeList_6（rtl/memblock/FreeList.sv 家族核 + FreeList_6.sv）
#   RRArbiterInit_11（rtl/common/RRArbiterInit.sv 家族核 + RRArbiterInit_11.sv）
#   PipelineRegModule / _1 / _2 ×3（本 lane 重写并签核，共用核 xs_PipelineRegModule_core）
# docs/coverage_three_axis.tsv 里前三类全部 PROVEN_DIRECT；PipelineRegModule 家族由本 lane 签核
# （evidence/48fbfd801873/）。处置 = **两侧白盒**：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
# 证明的是"golden 整棵子树 == 重写整棵子树"。
RTL_DIR  = ../../../rtl
UE_VARIANTS = UncacheEntry UncacheEntry_1 UncacheEntry_2 UncacheEntry_3 UncacheEntry_4 \
              UncacheEntry_5 UncacheEntry_6 UncacheEntry_7 UncacheEntry_8 UncacheEntry_9 \
              UncacheEntry_10 UncacheEntry_11 UncacheEntry_12 UncacheEntry_13 UncacheEntry_14 \
              UncacheEntry_15
RTL_SRCS = $(RTL_DIR)/memblock/LoadQueueUncache.sv \
           $(RTL_DIR)/memblock/PipelineRegModule.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_1.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_2.sv \
           $(RTL_DIR)/memblock/xs_UncacheEntry_core.sv \
           $(addprefix $(RTL_DIR)/memblock/,$(addsuffix .sv,$(UE_VARIANTS))) \
           $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/FreeList_6.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_11.sv
TB_SRCS  = tb.sv

LQU_CHILDREN = $(addsuffix .sv,$(UE_VARIANTS)) FreeList_6.sv RRArbiterInit_11.sv \
               PipelineRegModule.sv PipelineRegModule_1.sv PipelineRegModule_2.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueUncache.sv $(addprefix $(GOLDEN_RTL)/,$(LQU_CHILDREN))

FM_VARIANTS = LoadQueueUncache
FM_REF_DEPS_LoadQueueUncache = $(LQU_CHILDREN)

# 关掉 merge_duplicated_registers：golden 有值恒等的多份结构（每 lane 一份 RegNext(io.redirect)、
# 条目里的 flushPipe/replayInst 两个同函数寄存器），合并后两侧幸存者可能不同；
# 且只有关掉时 fm_predict 的 passing 模型才严格适用。这是加强不是放宽。
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
	python3 ../../../scripts/gen_lquncache.py --check
