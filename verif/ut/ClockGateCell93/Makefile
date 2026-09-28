MODULE = ClockGateCell93

# MbistClockGateCell_93（L2 数据阵列每 bank 的读时钟门控）与其 child ClockMux。
# ClockGate 是锁存器型门控单元模型（非 firtool 生成，coverage 里 GOLDEN_REUSE/PROVEN_IN_CONE），
# 与 SRAMTemplate_145 / DuplicatedTagArray 等先例一致：两侧同源读 golden ClockGate.sv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/MbistClockGateCell_93.sv $(RTL_DIR)/common/ClockMux.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MbistClockGateCell_93.sv $(GOLDEN_RTL)/ClockMux.sv
FM_VARIANTS = MbistClockGateCell_93 ClockMux
FM_REF_DEPS_MbistClockGateCell_93 = ClockGate.sv ClockMux.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
