# perfEventsModule —— PFEvent 里的 mhpmevent 影子寄存器（OPTYPE 字段 WARL）。golden 自足叶子。
MODULE = perfEventsModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/perfEventsModule.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/perfEventsModule.sv

FM_VARIANTS = perfEventsModule
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
