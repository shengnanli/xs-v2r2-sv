MODULE = LoadQueue_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）LoadQueue 簇：golden LoadQueue (u_g) vs 全重写 LoadQueue_it (u_i)
#
#   LoadQueue_it : 顶层端口 = golden LoadQueue；本体 = 重写 glue 核 xs_LoadQueue_core
#                  的逻辑（子队列互联 / full_mask 汇聚 / 异常 req 组装 / rollback 广播 /
#                  perf 两级打拍），但它例化的 6 个子队列**全部换成重写叶子 _xs 适配器**：
#                    LoadQueueRAR -> LoadQueueRAR_xs        VirtualLoadQueue -> VirtualLoadQueue_xs
#                    LoadQueueRAW -> LoadQueueRAW_xs        LqExceptionBuffer-> LqExceptionBuffer_xs
#                    LoadQueueReplay -> LoadQueueReplay_xs  LoadQueueUncache -> LoadQueueUncache_xs
#
#   每个 _xs（verif/ut/<M>/variants_xs.sv，纯端口搬运 + 重写 xs_<M>_core，无 golden 算法叶子）
#   内部只例化重写核；算法逻辑全部是重写件。本装配真正把
#   「重写 glue 核 ↔ 6 个重写子队列核」的集成边界全部连起来跑，
#   这是 per-module UT（单核被 golden 子队列包围）覆盖不到的部分。
#
#   叶子边界 = golden 存储/结构原语（两侧共享、非算法，xs 核内部也例化）：
#     xs_LoadQueueReplay_core 内：LqVAddrModule / FreeList_5 / AgeDetector_38
#     xs_LoadQueueUncache_core 内：UncacheEntry* / FreeList_6 / RRArbiterInit_9 / PipelineRegModule*
#   DelayN* 为纯延迟件（golden 与 rewrite 共用）。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：xs 核类型包 + 重写核 + 6 个叶子 _xs 适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/memblock/loadqueue_pkg.sv \
    $(RTL_DIR)/memblock/loadqueuerar_pkg.sv \
    $(RTL_DIR)/memblock/loadqueueraw_pkg.sv \
    $(RTL_DIR)/memblock/loadqueuereplay_pkg.sv \
    $(RTL_DIR)/memblock/virtualloadqueue_pkg.sv \
    $(RTL_DIR)/memblock/exceptionbuffer_pkg.sv \
    $(RTL_DIR)/memblock/loadqueueuncache_pkg.sv

# -- 重写 xs 子队列核（算法逻辑全部在这里；LoadQueue 顶层 glue 由 LoadQueue_it 提供）--
XS_CORES = \
    $(RTL_DIR)/memblock/LoadQueueRAR.sv \
    $(RTL_DIR)/memblock/LoadQueueRAW.sv \
    $(RTL_DIR)/memblock/LoadQueueReplay.sv \
    $(RTL_DIR)/memblock/VirtualLoadQueue.sv \
    $(RTL_DIR)/memblock/LqExceptionBuffer.sv \
    $(RTL_DIR)/memblock/LoadQueueUncache.sv

# -- 重写叶子适配器（golden 扁平端口 -> xs 核；复用各模块 UT 的 variants_xs.sv） --
XS_ADAPTERS = \
    $(UT_DIR)/LoadQueueRAR/variants_xs.sv \
    $(UT_DIR)/LoadQueueRAW/variants_xs.sv \
    $(UT_DIR)/LoadQueueReplay/variants_xs.sv \
    $(UT_DIR)/VirtualLoadQueue/variants_xs.sv \
    $(UT_DIR)/LqExceptionBuffer/variants_xs.sv \
    $(UT_DIR)/LoadQueueUncache/variants_xs.sv

# -- IT 装配（本目录；含本地 LoadQueue_inst_xs.svh：6 个子队列改用 _xs 实例的连接表）--
IT_ASSEMBLY = LoadQueue_it.sv

# ---------------------------------------------------------------------------
# golden 共享叶子（两侧共用）：6 个 golden 子队列（u_g 用）+ 子队列内部存储/结构原语
#   （xs_*_core 内部也例化这些：LqVAddrModule/FreeList_*/AgeDetector_38/UncacheEntry*/
#    RRArbiterInit_9/PipelineRegModule*）+ 纯延迟件 DelayN*。
#   = LoadQueue UT 的 GOLDEN_SUBS 闭包（35 文件），u_g 与 u_i 共用同一份。
# ---------------------------------------------------------------------------
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/AgeDetector_38.sv $(GOLDEN_RTL)/DelayNWithValid_103.sv \
  $(GOLDEN_RTL)/DelayNWithValid_148.sv $(GOLDEN_RTL)/DelayNWithValid_149.sv \
  $(GOLDEN_RTL)/DelayNWithValid_152.sv $(GOLDEN_RTL)/DelayNWithValid_155.sv \
  $(GOLDEN_RTL)/DelayNWithValid_4.sv $(GOLDEN_RTL)/DelayNWithValid_52.sv \
  $(GOLDEN_RTL)/DelayNWithValid_55.sv $(GOLDEN_RTL)/DelayNWithValid_7.sv \
  $(GOLDEN_RTL)/DelayN_13.sv $(GOLDEN_RTL)/DelayN_226.sv \
  $(GOLDEN_RTL)/DelayN_298.sv $(GOLDEN_RTL)/FreeList_3.sv \
  $(GOLDEN_RTL)/FreeList_4.sv $(GOLDEN_RTL)/FreeList_5.sv \
  $(GOLDEN_RTL)/FreeList_6.sv $(GOLDEN_RTL)/LoadQueueRAR.sv \
  $(GOLDEN_RTL)/LoadQueueRAW.sv $(GOLDEN_RTL)/LoadQueueReplay.sv \
  $(GOLDEN_RTL)/LoadQueueUncache.sv $(GOLDEN_RTL)/LqExceptionBuffer.sv \
  $(GOLDEN_RTL)/LqMaskModule.sv $(GOLDEN_RTL)/LqPAddrModule.sv \
  $(GOLDEN_RTL)/LqPAddrModule_1.sv $(GOLDEN_RTL)/LqVAddrModule.sv \
  $(GOLDEN_RTL)/PipelineRegModule.sv $(GOLDEN_RTL)/PipelineRegModule_1.sv \
  $(GOLDEN_RTL)/PipelineRegModule_2.sv $(GOLDEN_RTL)/RRArbiterInit_9.sv \
  $(GOLDEN_RTL)/UncacheEntry.sv $(GOLDEN_RTL)/UncacheEntry_1.sv \
  $(GOLDEN_RTL)/UncacheEntry_2.sv $(GOLDEN_RTL)/UncacheEntry_3.sv \
  $(GOLDEN_RTL)/VirtualLoadQueue.sv

# u_g 顶层独有：golden LoadQueue 顶层
GOLD_TOP = $(GOLDEN_RTL)/LoadQueue.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(GOLDEN_SUBS)

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir：xs 核 / LoadQueue_it 含 svh 片段（端口表/perf 接出在 rtl/memblock，
#          本地 LoadQueue_inst_xs.svh 在当前目录）。
VCS += +incdir+$(RTL_DIR)/memblock +incdir+.
# golden 子队列含 XSError/XSPerf/assert（非综合）；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
