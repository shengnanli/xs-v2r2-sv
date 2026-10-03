# WritebackEntry —— DCache WritebackQueue 的写回表项（两个变体共用 xs_WritebackEntry_core）。golden 自足叶子。
MODULE = WritebackEntry

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/WritebackEntry.sv $(RTL_DIR)/memblock/WritebackEntry_15.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/WritebackEntry.sv $(GOLDEN_RTL)/WritebackEntry_15.sv

FM_VARIANTS = WritebackEntry WritebackEntry_15
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
