MODULE = ExceptionGen

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_ExceptionGen_core + UT 变体包装 ExceptionGen_xs
RTL_SRCS = $(RTL_DIR)/backend/ExceptionGen.sv $(RTL_DIR)/backend/ExceptionGen_xs.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 ExceptionGen
WRAPPER_SRCS = $(RTL_DIR)/backend/ExceptionGen_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/ExceptionGen.sv
# UT 变体(impl 顶层改名 ExceptionGen_xs 与 golden 双例化)
TB_SRCS = tb.sv

# FM: 只比 ExceptionGen 顶层, 无依赖(自包含单模块 pipeline, 0 子模块 0 黑盒)
FM_VARIANTS = ExceptionGen

include ../../../scripts/ut_common.mk

# golden ExceptionGen 无 SYNTHESIS 断言, 但定义 SYNTHESIS 关随机初值注入
# 令两侧 reset 后同构; 配 +vcs+initreg+0 保 X 一致。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
