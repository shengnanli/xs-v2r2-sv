# Queue1_L1PrefetchReq —— L1 预取请求的深度 1 队列（xs_ChiselQueue1_core 薄变体，PIPE=0）。
MODULE = Queue1_L1PrefetchReq

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv $(RTL_DIR)/memblock/Queue1_L1PrefetchReq.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv

FM_VARIANTS = Queue1_L1PrefetchReq
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
