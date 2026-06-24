MODULE = StoreQueue_IT

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
UT_DIR     = ../../ut

# ===========================================================================
# IT（集成级）StoreQueue 簇：golden StoreQueue (u_g) vs 全重写 StoreQueue_it (u_i)
#
#   StoreQueue_it : 顶层端口 = golden StoreQueue（扁平 io_*，从 UT variants_xs 派生）；
#                   本体 = 重写 glue 核 xs_StoreQueue_core 的控制逻辑（环形指针推进 /
#                   per-entry 状态 / enq-commit-deq 仲裁 / forward 命中掩码 /
#                   mmio·nc·cmo 状态机 / deq 组 dataBuffer / redirect 回滚 / perf），
#                   但它例化的子模块中**唯一的重写算法叶子 StoreExceptionBuffer
#                   换成重写适配器 StoreExceptionBuffer_xs**：
#                     StoreExceptionBuffer -> StoreExceptionBuffer_xs (-> xs_StoreExceptionBuffer_core)
#
#   装配实现：
#     StoreQueue_it.sv            : 扁平 wrapper（= UT StoreQueue_xs 端口表，核换 _it）
#     xs_StoreQueue_core_it.sv    : = rtl/memblock/StoreQueue.sv 核体，仅 2 行差异——
#                                    模块名 + storequeue_subinst.svh -> 本地 _it 版
#     storequeue_subinst_it.svh   : = rtl 子例化表，唯一差异 StoreExceptionBuffer ->
#                                    StoreExceptionBuffer_xs（其余 4 子模块名不变）
#
#   => 把「重写 glue 核 xs_StoreQueue_core ↔ 重写异常缓冲核 xs_StoreExceptionBuffer_core」
#      的集成边界连起来跑，这是 per-module StoreQueue UT（excbuf 用 golden）覆盖不到的。
#
#   其余 4 子模块 SQDataModule / SQAddrModule / SQAddrModule_1 / DatamoduleResultBuffer
#   是数据/地址 SRAM 存储原语（工程未重写、无独立 xs 核），按 IT 规则作两侧共享 golden
#   存储原语保留（u_g 与 u_i 各自例化同一份，存储行为天然一致）。
# ===========================================================================

# ---------------------------------------------------------------------------
# 重写侧（u_i 链路）：pkg + 重写核（StoreQueue 核体 + StoreExceptionBuffer 核）
#                     + excbuf 叶子 _xs 适配器 + IT 装配
# ---------------------------------------------------------------------------
XS_PKGS = \
    $(RTL_DIR)/memblock/storequeue_pkg.sv \
    $(RTL_DIR)/memblock/exceptionbuffer_pkg.sv

# -- 重写核：StoreExceptionBuffer 核（StoreQueue 顶层 glue 由 xs_StoreQueue_core_it 提供）--
XS_CORES = \
    $(RTL_DIR)/memblock/StoreExceptionBuffer.sv

# -- 重写叶子适配器（golden 扁平端口 -> xs 核；复用 StoreExceptionBuffer UT 的 variants_xs.sv）--
XS_ADAPTERS = \
    $(UT_DIR)/StoreExceptionBuffer/variants_xs.sv

# -- IT 装配（本目录：扁平 wrapper + 核体 _it + 本地子例化表 svh）--
IT_ASSEMBLY = \
    xs_StoreQueue_core_it.sv \
    StoreQueue_it.sv

# ---------------------------------------------------------------------------
# golden 共享叶子（两侧共用）：golden StoreQueue 顶层（u_g）+ 5 个数据/地址存储子模块
#   （xs_StoreQueue_core_it 内部也例化其中 4 个 SRAM 原语；StoreExceptionBuffer 仅 u_g 用）
# ---------------------------------------------------------------------------
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/SQDataModule.sv $(GOLDEN_RTL)/SQData8Module.sv \
  $(GOLDEN_RTL)/SQAddrModule.sv $(GOLDEN_RTL)/SQAddrModule_1.sv \
  $(GOLDEN_RTL)/DatamoduleResultBuffer.sv $(GOLDEN_RTL)/StoreExceptionBuffer.sv

# u_g 顶层独有：golden StoreQueue 顶层
GOLD_TOP = $(GOLDEN_RTL)/StoreQueue.sv

# ---------------------------------------------------------------------------
# 汇总给 ut_common.mk
# ---------------------------------------------------------------------------
RTL_SRCS = $(XS_PKGS) $(XS_CORES) $(XS_ADAPTERS) $(IT_ASSEMBLY)

GOLDEN_SRCS = $(GOLD_TOP) $(GOLDEN_SUBS)

TB_SRCS = tb.sv

# IT 不做 FM（FM 是 per-module 等价证明的事）；此处置空。
FM_VARIANTS =

include ../../../scripts/ut_common.mk

# +incdir：xs_StoreQueue_core_it 含 storequeue_*.svh 片段（端口/ebdecl/rdyvec/body 在
#          rtl/memblock；本地 storequeue_subinst_it.svh 在当前目录，须先搜本地）。
VCS += +incdir+. +incdir+$(RTL_DIR)/memblock
# golden 子模块/顶层含 XSError/XSPerf/assert（非综合）；关掉以免随机激励误触 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
# +vcs+initreg+0（runtime）：无 reset 寄存器清 0，保证两侧从同一确定态出发。
SIM_ARGS += +vcs+initreg+0
