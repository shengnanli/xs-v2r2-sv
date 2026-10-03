MODULE = StrideMetaArray

# L1 stride 预取器的 PC 步长表（单文件：核 + golden 同名 wrapper）。无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/StrideMetaArray.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StrideMetaArray.sv

FM_VARIANTS = StrideMetaArray
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 表项字段与 s1~s4 数据寄存器不复位：valid 为 0 时输出里的数据是未定义初值，tb 只在 valid=1 时比数据。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
