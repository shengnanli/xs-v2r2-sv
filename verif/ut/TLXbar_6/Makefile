MODULE = TLXbar_6

# L2Top 的 mmio_xbar（2 主 × 3 从 TileLink-UL 交叉开关）。核 xs_TLXbar_6_core + 共享仲裁器
# rtl/common/xs_TLArbiterRoundRobin.sv（TLArbiter.roundRobin 的可读实现）。无子模块黑盒。
# fm_pins_pre.tcl：golden 五个内联仲裁器的 beatsLeft/readys_mask/state 与核里 u_arb 实例寄存器一一钉点。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_TLArbiterRoundRobin.sv $(RTL_DIR)/uncore/TLXbar_6.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_6.sv
FM_VARIANTS = TLXbar_6
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
