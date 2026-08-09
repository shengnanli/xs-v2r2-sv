MODULE = FrontendTrigger

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_FrontendTrigger_core + UT 变体包装 FrontendTrigger_xs
RTL_SRCS = $(RTL_DIR)/frontend/FrontendTrigger.sv $(RTL_DIR)/frontend/FrontendTrigger_xs.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 FrontendTrigger
WRAPPER_SRCS = $(RTL_DIR)/frontend/FrontendTrigger_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/FrontendTrigger.sv
TB_SRCS = tb.sv

# FM: 只比 FrontendTrigger 顶层(自包含单模块, 0 子模块 0 黑盒)。
# impl tdata2 收窄至 golden 读域 [49:0] → 残留 golden-only cone-dead
# tdataVec_*_tdata2[63:50], 逐点申报 verif/signoff/dead_ref/FrontendTrigger.json。
FM_VARIANTS = FrontendTrigger
# timing 寄存器写恒 0(golden: ~wen & timing, reset 0)→ 两侧皆常数; 默认
# merge_duplicated_registers=true 会把 impl 侧 timing_1..3 常量合并掉, 而 golden
# 侧保留 4 个 Constrained-0X 孤儿 → 3 unmatched_ref 伪影。关合并(更严不更松),
# 让两侧常数寄存器按名配对。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 无 SYNTHESIS 断言, 但定义 SYNTHESIS 关随机初值注入; 异步 reset 全零,
# 配 +vcs+initreg+0 令两侧起始态同构。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
