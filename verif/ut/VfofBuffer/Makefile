MODULE = VfofBuffer

# VfofBuffer（vleff 的 vl 修正单条目缓冲）。golden 无子模块；全部寄存器异步复位。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/VfofBuffer.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/VfofBuffer.sv
FM_VARIANTS = VfofBuffer

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在它关掉时严格适用。加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值。本件所有寄存器都有异步复位，三档结果应相同。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
