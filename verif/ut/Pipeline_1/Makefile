# Pipeline_1 —— L2 预取器出口的一级流水（utility.Pipeline depth=1）；唯一子模块 Queue1_PrefetchReq 两侧白盒：ref 读 golden、impl 读重写件（已签核）。
MODULE = Pipeline_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv $(RTL_DIR)/frontend/Queue1_PrefetchReq.sv $(RTL_DIR)/uncore/Pipeline_1.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_1.sv $(GOLDEN_RTL)/Queue1_PrefetchReq.sv
FM_REF_DEPS_Pipeline_1 = Queue1_PrefetchReq.sv

FM_VARIANTS = Pipeline_1
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
