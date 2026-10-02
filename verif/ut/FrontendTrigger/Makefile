# FrontendTrigger —— 前端取指断点触发器（4 个 mcontrol execute 触发器 × 16 个 PC 位置）。
# 自足叶子：无子模块、无黑盒。全部寄存器异步复位。
MODULE = FrontendTrigger

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/FrontendTrigger.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FrontendTrigger.sv

FM_VARIANTS = FrontendTrigger
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
