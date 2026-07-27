MODULE = RedirectGenerator

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读逻辑核。
RTL_SRCS = $(RTL_DIR)/backend/RedirectGenerator.sv

# UT 用 _xs 变体(golden 同名从 GOLDEN_SRCS 例化, 避免撞名)。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层(纯叶子, 无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/RedirectGenerator.sv

# FM: golden RedirectGenerator vs 手写同名 wrapper(仅 FM 用)。
WRAPPER_SRCS = $(RTL_DIR)/backend/RedirectGenerator_wrapper.sv
FM_VARIANTS = RedirectGenerator

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
