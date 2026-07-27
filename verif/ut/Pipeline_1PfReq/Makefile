MODULE = Pipeline_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 xs_Pipeline_1_core + 深度1队列核 xs_Queue1_PrefetchReq_core。
RTL_SRCS = $(RTL_DIR)/l2/Pipeline_1.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/Pipeline_1_wrapper.sv
# golden 顶层 + 其唯一子模块 Queue1_PrefetchReq(ref 侧例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_1.sv $(GOLDEN_RTL)/Queue1_PrefetchReq.sv
# UT 变体: impl 顶层改名 Pipeline_1_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; golden 侧依赖 Queue1_PrefetchReq(在 ref 侧 elaborate),
# impl 侧例化可读 xs_Queue1_PrefetchReq_core, FM 逐位证明整体(含深度1队列)等价。
FM_VARIANTS = Pipeline_1
FM_REF_DEPS_Pipeline_1 = Queue1_PrefetchReq.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
