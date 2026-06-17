MODULE = Fence

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（无子模块，纯叶子 FU）
RTL_SRCS = $(RTL_DIR)/backend/fence_pkg.sv \
           $(RTL_DIR)/backend/Fence.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化用 golden 顶层 Fence
GOLDEN_SRCS = $(GOLDEN_RTL)/Fence.sv

# FM：golden Fence vs 手写同名 wrapper（→ 可读核），无子模块依赖
WRAPPER_SRCS = $(RTL_DIR)/backend/Fence_wrapper.sv
FM_VARIANTS = Fence
FM_REF_DEPS_Fence =

include ../../../scripts/ut_common.mk

# golden 内含 Scala assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
