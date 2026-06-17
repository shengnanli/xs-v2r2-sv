MODULE = WbFuBusyTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核: 类型包 + 组合核(纯叶子, 无黑盒子模块)。
RTL_SRCS = $(RTL_DIR)/backend/wbfubusytable_pkg.sv \
           $(RTL_DIR)/backend/WbFuBusyTable.sv

# UT 用 _xs 镜像(变体), 与 golden 双例化逐拍比对。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 WbFuBusyTable 为纯叶子, 无子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/WbFuBusyTable.sv

# FM: golden 顶层 WbFuBusyTable vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/WbFuBusyTable_wrapper.sv
FM_VARIANTS = WbFuBusyTable
FM_REF_DEPS_WbFuBusyTable =

include ../../../scripts/ut_common.mk

# 纯组合无随机初始化; 关 SYNTHESIS 以与可读核对齐(golden 无断言)。
VCS += +define+SYNTHESIS
