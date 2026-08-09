MODULE = VBestOffsetPrefetch

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_VBestOffsetPrefetch_core + 三小子核(V 版)。
# 复用 PBestOffset_children.sv 的 xs_SRAMTemplate_135_core(RecentRequestTable_1 内例化)。
# 追加 reqFilter 可读核 xs_PrefetchReqBuffer_core(PrefetchReqBuffer.sv, 已独立签绿)——
# VBestOffset core 内例化的 PrefetchReqBuffer 由此实现, 不再是黑盒。
RTL_SRCS = $(RTL_DIR)/l2/VBestOffsetPrefetch.sv \
           $(RTL_DIR)/l2/VBestOffset_children.sv \
           $(RTL_DIR)/l2/PBestOffset_children.sv \
           $(RTL_DIR)/l2/PrefetchReqBuffer.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
# PrefetchReqBuffer_wrapper.sv 定义 module PrefetchReqBuffer(=xs_PrefetchReqBuffer_core
# 扁平端口壳), 令 VBestOffset core 的 reqFilter 例化在 impl 侧两侧同源 elaborate。
# 其两个 RRArbiterInit_12/_13(确定性轮转仲裁, 非厂商宏)golden 定义两侧共用(消黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/l2/VBestOffsetPrefetch_wrapper.sv \
               $(RTL_DIR)/l2/PrefetchReqBuffer_wrapper.sv \
               $(GOLDEN_RTL)/RRArbiterInit_12.sv $(GOLDEN_RTL)/RRArbiterInit_13.sv
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

# FM: 单顶层 strict; 三小子核 + SRAM 控制 + reqFilter(PrefetchReqBuffer)两侧可读
# elaborate; 唯一对称黑盒 = 厂商 SRAM 宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt。
# reqFilter 现两侧同源 elaborate(golden PrefetchReqBuffer.sv+RRArbiterInit_12/_13 进
# ref; impl xs_PrefetchReqBuffer_core+wrapper+同一 RRArbiterInit 进 impl)→其内部逻辑
# 逐点比较(passing 1574→4451, codex_0073 phase1 收口: PrefetchReqBuffer 已独立 PASS)。
# 唯一残余 384 unread = DelayQueue_1 的 queue_<N>_addrNoOffset[43:20](16 条目×24 顶位,
# golden 存 44 位只读低 20 位, ref/impl 两侧对称死位, 非 PrefetchReqBuffer 边界)——
# fm_pins_pre.tcl 建双射 + verify_matched_unread_compare_points=true 让 FM 逐位实证相等
# →从 Not-Compared 提升为 Passing(加强证明, 非 waiver; 见 fm_pins_pre.tcl 详注)。
FM_VARIANTS = VBestOffsetPrefetch
FM_MODE = assembly
FM_ALLOWLIST = ../../signoff/allow/VBestOffsetPrefetch.json
FM_REF_DEPS_VBestOffsetPrefetch = DelayQueue_1.sv RecentRequestTable_1.sv OffsetScoreTable_1.sv SRAMTemplate_135.sv \
                                  PrefetchReqBuffer.sv RRArbiterInit_12.sv RRArbiterInit_13.sv

# reqFilter(PrefetchReqBuffer)两侧真 elaborate 后, 其内部 146 对称死位提升为实际比较。
# VBestOffsetPrefetch 须在 fm_eq.tcl/run_signoff_target.sh 的 matched-unread 白名单中
# (standing rule; 本 worker 已加 VBestOffsetPrefetch 到 fm_eq.tcl 白名单并报 main)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
