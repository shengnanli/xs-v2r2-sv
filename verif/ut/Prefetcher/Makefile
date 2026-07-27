MODULE = Prefetcher

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_Prefetcher_core(顶层 glue 重写, 6 子模块按 golden 名例化)。
# UT 双例化中 golden Prefetcher 与 Prefetcher_xs 共用同一份 golden 子模块定义
# (单例), 故被测的只有本核的顶层 glue。
RTL_SRCS = $(RTL_DIR)/l2/Prefetcher.sv
# FM impl 侧: golden 同名扁平端口包装 + PrefetchQueue 两侧 elaborate(golden RTL,
# 逻辑 child 非黑盒)。5 绿 child 不列 → impl 侧亦 unresolved → 对称黑盒。
WRAPPER_SRCS = $(RTL_DIR)/l2/Prefetcher_wrapper.sv $(GOLDEN_RTL)/PrefetchQueue.sv

# golden 顶层 + 6 直接子模块 + 传递闭包(含厂商 SRAM 宏行为模型, 两侧共用单例)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Prefetcher.sv \
              $(GOLDEN_RTL)/PBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/VBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/PrefetchReceiver.sv \
              $(GOLDEN_RTL)/MbistPipeL2Prefetcher.sv \
              $(GOLDEN_RTL)/PrefetchQueue.sv \
              $(GOLDEN_RTL)/Pipeline_1.sv \
              $(GOLDEN_RTL)/DelayQueue.sv \
              $(GOLDEN_RTL)/DelayQueue_1.sv \
              $(GOLDEN_RTL)/OffsetScoreTable.sv \
              $(GOLDEN_RTL)/OffsetScoreTable_1.sv \
              $(GOLDEN_RTL)/RecentRequestTable.sv \
              $(GOLDEN_RTL)/RecentRequestTable_1.sv \
              $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/Queue1_PrefetchReq.sv \
              $(GOLDEN_RTL)/RRArbiterInit_12.sv \
              $(GOLDEN_RTL)/RRArbiterInit_13.sv \
              $(GOLDEN_RTL)/SRAMTemplate_135.sv \
              $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
              $(GOLDEN_RTL)/array_13.sv \
              $(GOLDEN_RTL)/array_13_ext.v
# UT 变体: impl 顶层改名 Prefetcher_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 assembly。5 绿 AUX child(pbop/vbop/pfRcv/mbistPl/pipe)两侧
# unresolved → hdlin_unresolved_modules=black_box 对称边界(assembly depends_on;
# allow/Prefetcher.json 声明)。PrefetchQueue 两侧 elaborate golden RTL(逻辑 child,
# 非黑盒, ref==impl 由同源 golden 保证; 待独立 signoff 后 Prefetcher 全子树绿)。
FM_VARIANTS = Prefetcher
FM_MODE = assembly
FM_REF_DEPS_Prefetcher = PrefetchQueue.sv
FM_INTERFACE_ONLY = 1

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值/断言; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
VCS += +libext+.sv+.v
VCS += -assert disable
