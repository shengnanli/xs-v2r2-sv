MODULE = DelayN_15

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + golden 同名 wrapper。
RTL_SRCS = $(RTL_DIR)/backend/DelayN.sv

# UT 用 _xs 变体(与 golden 同时例化)。
TB_SRCS = $(RTL_DIR)/backend/DelayN_variants_xs.sv tb.sv

# golden 顶层(纯叶子, 无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN_15.sv

# FM: golden DelayN_15 vs 手写同名 wrapper(-> 通用延迟核)。
WRAPPER_SRCS =
FM_VARIANTS = DelayN_15

include ../../../scripts/ut_common.mk

# golden 在 SYNTHESIS 下关随机初始化。
VCS += +define+SYNTHESIS
