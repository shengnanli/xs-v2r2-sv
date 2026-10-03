MODULE = TLXbar_5

# L2Top 的 l1_xbar（3 主 × 4 从 TileLink-C 交叉开关，L1 到 L2 四个 bank）。核 xs_TLXbar_5_core（结构体端口；wrapper 由 scripts/gen_tlxbar5_wrapper.py 生成）+ 共享仲裁器
# rtl/common/xs_TLArbiterRoundRobin.sv（TLArbiter.roundRobin 的可读实现）。无子模块黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_TLArbiterRoundRobin.sv $(RTL_DIR)/uncore/TLXbar_5.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_5.sv
FM_VARIANTS = TLXbar_5
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
