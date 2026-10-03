# Queue1_RegMapperInput_6 —— DCache CtrlUnit 的 A 通道深度 1 队列（TLRegisterNode 自动插入）。
# 薄变体：核体 xs_Queue1_RegMapperInput 在 rtl/frontend/ICacheCtrlUnit.sv（与 _5 共用，核未改）。
MODULE = Queue1_RegMapperInput_6

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
           $(RTL_DIR)/memblock/Queue1_RegMapperInput_6.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Queue1_RegMapperInput_6.sv

FM_VARIANTS = Queue1_RegMapperInput_6
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
