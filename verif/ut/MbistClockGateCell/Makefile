MODULE = MbistClockGateCell

# MbistClockGateCell（SRAMTemplate 系列的 SRAM 时钟门控单元，mcpCtl=false 款）。
# 唯一 child ClockGate 是本地重写共享基元（rtl/common/ClockGate.sv，codex 0208 已签）：
# impl 读本地件、ref 读 golden。0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/MbistClockGateCell.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
FM_VARIANTS = MbistClockGateCell
FM_REF_DEPS_MbistClockGateCell = ClockGate.sv
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
