MODULE = MbistIntfL2

# MbistIntfL2：L2 MBIST 分发树树根（utility.mbist.MbistInterface，只挂一棵子树 = 纯直通）。
# 0 子模块、0 寄存器、0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/dft/MbistIntfL2.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MbistIntfL2.sv
FM_VARIANTS = MbistIntfL2
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器；initreg 三档照常给（统一口径），对结果无影响。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
