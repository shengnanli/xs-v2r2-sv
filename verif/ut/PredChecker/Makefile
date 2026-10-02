# PredChecker —— 预测结果的预译码检查（stage1 组合 + stage2 打一拍）。
# 自足叶子：无子模块、无黑盒、无 reset 端口（寄存器全部不复位，fire_in 使能）。
MODULE = PredChecker

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/PredChecker.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PredChecker.sv

FM_VARIANTS = PredChecker
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
