MODULE = AsyncResetSyncPrim_d3_i0

# AsyncResetSynchronizerPrimitiveShiftReg_d3_i0：rocket-chip 3 级异步复位（复位值 0）同步器的单比特原语。
# 核内经 CSR -> IMSIC_WRAP -> IMSIC -> IMSICGateWay -> AsyncResetSynchronizerShiftReg_w1_d3_i0 到达
# （boundary_ledger: WORK_REACHABLE / DESIGN，非厂商宏）。0 子模块、0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
FM_VARIANTS = AsyncResetSynchronizerPrimitiveShiftReg_d3_i0
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 3 个寄存器全异步复位到 0。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
