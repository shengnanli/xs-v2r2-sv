MODULE = MaxPeriodFibonacciLFSR

# 15 位最大周期 Fibonacci LFSR（Tage_SC / ITTage 的分配随机源）。golden 0 child，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/MaxPeriodFibonacciLFSR.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

FM_VARIANTS = MaxPeriodFibonacciLFSR
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
