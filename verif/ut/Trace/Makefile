MODULE = Trace

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读顶层 glue 核(UT + FM impl 两侧)。
RTL_SRCS = $(RTL_DIR)/backend/Trace.sv

# UT 用 _xs 变体。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + TraceBuffer 子(UT: golden Trace 与 Trace_xs 共享同一份 golden TraceBuffer)。
GOLDEN_SRCS = $(GOLDEN_RTL)/Trace.sv \
              $(GOLDEN_RTL)/TraceBuffer.sv

# FM impl 侧: 手写 wrapper + golden TraceBuffer(两侧同源 elaborate 非黑盒)。
# TraceBuffer 为叶子逻辑模块(无子模块)。
WRAPPER_SRCS = $(RTL_DIR)/backend/Trace_wrapper.sv \
               $(GOLDEN_RTL)/TraceBuffer.sv
FM_VARIANTS = Trace
FM_REF_DEPS_Trace = TraceBuffer.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
