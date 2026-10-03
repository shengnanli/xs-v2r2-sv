# Arbiter8_MainPipeReq —— ProbeQueue 的 8 选 1 probe 仲裁器（xs_FixedPriorityArbiter_core 变体）。纯组合。
MODULE = Arbiter8_MainPipeReq

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv $(RTL_DIR)/memblock/Arbiter8_MainPipeReq.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv

FM_VARIANTS = Arbiter8_MainPipeReq
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
