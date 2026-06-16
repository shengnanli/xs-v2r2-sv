MODULE = LoadQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核通过 `include 引入端口表 / 实例表 / perf 接出）
RTL_SRCS = $(RTL_DIR)/memblock/loadqueue_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueue.sv

TB_SRCS = variants_xs.sv tb.sv

# golden LoadQueue 例化 6 个子队列，其传递闭包共 35 个 golden 文件（不含 LoadQueue 顶层）。
# UT 双例化两侧（u_g 用 golden 顶层，u_i 用手写核）都引用这同一批 golden 子队列。
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

GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueue.sv $(GOLDEN_SUBS)

# FM：golden 顶层 LoadQueue vs 手写同名 wrapper（→ 可读核 + pkg）。
# 两侧都读入同一批 golden 子队列，使 ref 与 impl 各自把队列实化为同一份定义：
# 队列内部寄存器逐位等价、自动配对通过；FM 真正验证的是顶层 glue（子队列互联 /
# full_mask 汇聚 / 异常 req 组装 / rollback 广播 / perf 打拍）相对真实队列输出是否
# 等价。（若把队列当黑盒，FM 因黑盒输出网无法配对，会在依赖队列输出的 full_mask/
# perf 上误报；故两侧都喂真实队列定义。）
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueue_wrapper.sv $(GOLDEN_SUBS)
FM_VARIANTS = LoadQueue
FM_REF_DEPS_LoadQueue = AgeDetector_38.sv DelayNWithValid_103.sv \
  DelayNWithValid_148.sv DelayNWithValid_149.sv DelayNWithValid_152.sv \
  DelayNWithValid_155.sv DelayNWithValid_4.sv DelayNWithValid_52.sv \
  DelayNWithValid_55.sv DelayNWithValid_7.sv DelayN_13.sv DelayN_226.sv \
  DelayN_298.sv FreeList_3.sv FreeList_4.sv FreeList_5.sv FreeList_6.sv \
  LoadQueueRAR.sv LoadQueueRAW.sv LoadQueueReplay.sv LoadQueueUncache.sv \
  LqExceptionBuffer.sv LqMaskModule.sv LqPAddrModule.sv LqPAddrModule_1.sv \
  LqVAddrModule.sv PipelineRegModule.sv PipelineRegModule_1.sv \
  PipelineRegModule_2.sv RRArbiterInit_9.sv UncacheEntry.sv UncacheEntry_1.sv \
  UncacheEntry_2.sv UncacheEntry_3.sv VirtualLoadQueue.sv

# 队列里大量 N 表项结构相同的寄存器，关掉“合并同值重复寄存器”pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子队列含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口表 / 实例表 / perf 接出）
VCS += +incdir+$(RTL_DIR)/memblock
