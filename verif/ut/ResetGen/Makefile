MODULE = ResetGen

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + golden 同名 wrapper (同一文件)。
RTL_SRCS = $(RTL_DIR)/uncore/ResetGen.sv

TB_SRCS = tb.sv

# golden 顶层 (纯叶子, 无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/ResetGen.sv

# FM: ref = golden ResetGen.sv; impl = 可读核 + wrapper (RTL_SRCS 内)。
# wrapper 与核在同一 RTL_SRCS 文件, 无独立 WRAPPER_SRCS。
WRAPPER_SRCS =
FM_VARIANTS = ResetGen

include ../../../scripts/ut_common.mk

# golden 在 SYNTHESIS 下关随机初始化。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
