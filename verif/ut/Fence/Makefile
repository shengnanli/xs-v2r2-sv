MODULE = Fence

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Fence.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# Fence 是纯叶子 FU：golden 无任何子模块实例，故无 golden 依赖闭包、无黑盒。
GOLDEN_SRCS = $(GOLDEN_RTL)/Fence.sv

FM_VARIANTS = Fence
FM_REF_DEPS_Fence =

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2（Scala assert 的落地），
# 编译期就会报未定义函数；UT 两侧统一定义 SYNTHESIS 把断言段关掉。
VCS += +define+SYNTHESIS
