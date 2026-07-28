MODULE = IntBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + golden 同名 wrapper (同一文件)。
RTL_SRCS = $(RTL_DIR)/uncore/IntBuffer.sv

TB_SRCS = tb.sv

# golden 顶层 (纯叶子, 无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/IntBuffer.sv

# FM: ref = golden IntBuffer.sv; impl = 可读核 + wrapper (RTL_SRCS 内)。
WRAPPER_SRCS =
FM_VARIANTS = IntBuffer

include ../../../scripts/ut_common.mk

# golden 在 SYNTHESIS 下关随机初始化。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
