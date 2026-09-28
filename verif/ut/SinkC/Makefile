MODULE = SinkC

# SinkC（TileLink C 通道入口）。golden child：RRArbiterInit_16（taskArb，PROVEN_DIRECT，
# 共用核 xs_RRArbiterInit_core 在 rtl/common/RRArbiterInit.sv），两侧白盒。0 黑盒。
# 可读核 xs_SinkC_core 手写；TaskBundle 结构体与 wrapper 由 scripts/gen_l2_sinkc.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SinkC.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv $(RTL_DIR)/common/RRArbiterInit_16.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SinkC.sv $(GOLDEN_RTL)/RRArbiterInit_16.sv
FM_VARIANTS = SinkC
FM_REF_DEPS_SinkC = RRArbiterInit_16.sv
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
