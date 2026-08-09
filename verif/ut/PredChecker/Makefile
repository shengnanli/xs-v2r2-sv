MODULE = PredChecker

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_PredChecker_core + UT 变体包装 PredChecker_xs
RTL_SRCS = $(RTL_DIR)/frontend/PredChecker.sv $(RTL_DIR)/frontend/PredChecker_xs.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 PredChecker
WRAPPER_SRCS = $(RTL_DIR)/frontend/PredChecker_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/PredChecker.sv
TB_SRCS = tb.sv

# FM: 只比 PredChecker 顶层(自包含单模块, 0 子模块 0 黑盒)
FM_VARIANTS = PredChecker

include ../../../scripts/ut_common.mk

# golden 无 SYNTHESIS 断言, 但定义 SYNTHESIS 关随机初值注入; PredChecker 寄存器
# 全部无 reset(仅 fire_in 使能), 配 +vcs+initreg+0 令两侧起始态同构。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
