MODULE = AsyncResetSyncShiftReg_w1_d3_i0

# AsyncResetSynchronizerShiftReg_w1_d3_i0：rocket-chip 1 位 3 级异步复位同步器装配壳，
# 只例化一条 AsyncResetSynchronizerPrimitiveShiftReg_d3_i0（output_chain）。
# child 原语 PROVEN_DIRECT（verif/ut/AsyncResetSyncPrim_d3_i0）：两侧白盒，
# ref 读 golden 原语、impl 读本仓重写件。0 黑盒。
RTL_DIR  = ../../../rtl
# child 重写件也列进 RTL_SRCS：UT 里派生成 _xs，两侧各用各的 child（golden 侧 golden 原语）。
RTL_SRCS = $(RTL_DIR)/uncore/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
           $(RTL_DIR)/uncore/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
FM_VARIANTS = AsyncResetSynchronizerShiftReg_w1_d3_i0
FM_REF_DEPS_AsyncResetSynchronizerShiftReg_w1_d3_i0 = AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
