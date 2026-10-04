# ProbeEntry —— DCache ProbeQueue 的单个 probe 表项（3 态状态机）。golden 自足叶子，无子模块。
MODULE = ProbeEntry

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/ProbeEntry.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ProbeEntry.sv

FM_VARIANTS = ProbeEntry
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
