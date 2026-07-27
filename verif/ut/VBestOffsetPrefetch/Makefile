MODULE = VBestOffsetPrefetch

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_VBestOffsetPrefetch_core + 三小子核(V 版)。
# 复用 PBestOffset_children.sv 的 xs_SRAMTemplate_135_core(RecentRequestTable_1 内例化)。
RTL_SRCS = $(RTL_DIR)/l2/VBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/VBestOffset_children.sv \
           $(RTL_DIR)/l2/PBestOffset_children.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/VBestOffsetPrefetch_wrapper.sv
# golden 顶层 + 三小子模块 + SRAMTemplate_135。
# UT 仿真需真 PrefetchReqBuffer(+2 RRArbiterInit)与 SRAM 宏行为模型(golden 与 impl
# 两侧共用同一 PrefetchReqBuffer/sram_array_ 定义)。FM 侧(FM_REF_DEPS)不含这些 → 对称黑盒。
GOLDEN_SRCS = $(GOLDEN_RTL)/VBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/DelayQueue_1.sv \
              $(GOLDEN_RTL)/RecentRequestTable_1.sv \
              $(GOLDEN_RTL)/OffsetScoreTable_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_135.sv \
              $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/RRArbiterInit_12.sv \
              $(GOLDEN_RTL)/RRArbiterInit_13.sv \
              $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
              $(GOLDEN_RTL)/array_13.sv \
              $(GOLDEN_RTL)/array_13_ext.v
# UT 变体: impl 顶层改名 VBestOffsetPrefetch_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; 三小子核 + SRAM 控制两侧可读 elaborate; 两个对称黑盒:
#   (1) 厂商 SRAM 宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt;
#   (2) PrefetchReqBuffer(TLB 请求过滤缓冲, 1715 行 + 2 RRArbiterInit; 本轮作用域外,
#       需独立子证明)。二者两侧 unresolved → hdlin_unresolved_modules=black_box 对称匹配。
FM_VARIANTS = VBestOffsetPrefetch
FM_REF_DEPS_VBestOffsetPrefetch = DelayQueue_1.sv RecentRequestTable_1.sv OffsetScoreTable_1.sv SRAMTemplate_135.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
