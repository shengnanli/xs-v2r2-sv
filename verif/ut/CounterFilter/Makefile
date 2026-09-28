# CounterFilter —— DCache "有用预取"计数去重 FIFO（15 项循环队列 + 3 口全相联查询）。
# 自足叶子：无子模块、无黑盒。
MODULE = CounterFilter

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/CounterFilter.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CounterFilter.sv

FM_VARIANTS = CounterFilter
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
